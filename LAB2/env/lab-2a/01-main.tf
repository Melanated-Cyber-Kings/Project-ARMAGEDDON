terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" 
    }
  }
}

######################################################################################
# 1: DATA SOURCES & IDENTITY (DUAL-REGION)
######################################################################################

data "aws_secretsmanager_secret" "rds" {
  name = var.db_secret_name
}

data "aws_secretsmanager_secret_version" "rds" {
  secret_id = data.aws_secretsmanager_secret.rds.id
}

# 2. THE EDGE CERT (VIRGINIA)
resource "aws_acm_certificate" "edge_cert" {
  provider          = aws.us_east_1 
  domain_name       = var.domain_name
  validation_method = "DNS"
  
  lifecycle { create_before_destroy = true }
  tags = merge(local.tags, { Name = "${local.name_prefix}-edge-cert" })
}

# 3. THE ORIGIN CERT (TOKYO)
resource "aws_acm_certificate" "origin_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  
  lifecycle { create_before_destroy = true }
  tags = merge(local.tags, { Name = "${local.name_prefix}-origin-cert" })
}

######################################################################################
# PHASE 2: LOGGING POLICY 
######################################################################################

resource "aws_s3_bucket_policy" "alb_logging_policy" {
  bucket = module.s3_logs.bucket_id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowELBLogDelivery"
        Effect = "Allow",
        Principal = {
          # Tokyo ELB Account ID
          AWS = "arn:aws:iam::582318560864:root" 
        },
        Action   = "s3:PutObject",
        Resource = "${module.s3_logs.bucket_arn}/*"
      }
    ]
  })
}

######################################################################################
# 3: REGIONAL
######################################################################################

# 1. Networking
module "vpc" {
  source                   = "../../modules/network"
  vpc_cidr_block           = var.vpc_cidr_block
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_subnet_cidrs_app = var.private_subnet_cidrs_app
  private_subnet_cidrs_db  = var.private_subnet_cidrs_db
  azs                      = var.avail_zones
  name_prefix               = local.name_prefix
  rtb_public_cidr          = var.rtb_public_cidr
}

# 2. S3 Logs Storage
module "s3_logs" {
  source      = "../../modules/s3"
  bucket_name = "${local.name_prefix}-alb-logs-${var.account_id}"
  name_prefix = local.name_prefix
}

# 3. IAM
module "iam" {
  source      = "../../modules/iam"
  region      = var.region
  account_id  = var.account_id
  name_prefix = local.name_prefix
}

# 4. Security Groups
module "security" {
  source      = "../../modules/security"
  vpc_id      = module.vpc.vpc_id
  name_prefix = local.name_prefix
  alb_sg_id   = module.security.alb_sg_id 
  tcp_ingress_rule = {
    port        = 3306
    description = "MySQL access from EC2"
  }
}

# 5. App Server
module "ec2" {
  source                = "../../modules/ec2"
  name_prefix           = local.name_prefix
  subnet_id             = module.vpc.private_app_subnet_ids[0]
  instance_type         = var.instance_type
  security_group_ids    = [module.security.ec2_sg_id]
  region                = var.region
  instance_profile_name = module.iam.instance_profile_name
  
  user_data = templatefile("${path.module}/user_data.sh", {
    region    = var.region
    secret_id = var.db_secret_name
  })
}

# 6. Database (RDS MySQL)
module "rds" {
  source                = "../../modules/rds"
  db_name               = local.db_name
  db_username           = local.rds_secret.username
  db_password           = local.rds_secret.password
  db_subnet_group_name  = module.vpc.db_subnet_group_name
  rds_security_group_id = module.security.rds_sg_id
}

######################################################################################
# 4: GLOBAL EDGE LAYER
######################################################################################

# 1. ALB
module "alb" {
  source             = "../../modules/alb"
  name_prefix        = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_ids = [module.security.alb_sg_id]
  target_id          = module.ec2.ec2_id
  
  # Handshake Logic (Cloaking)
  header_name        = local.header_name
  header_value       = local.header_value
  https_listener_arn = module.alb.https_listener_arn 
  target_group_arn   = module.alb.target_group_arn
  
  access_logs_bucket = module.s3_logs.bucket_id 
  certificate_arn    = aws_acm_certificate.origin_cert.arn # TOKYO CERT

  depends_on = [aws_s3_bucket_policy.alb_logging_policy]
}

# 2. WAF
module "waf" {
  source      = "../../modules/waf"
  name_prefix = local.name_prefix
  providers   = { aws = aws.us_east_1 }
}

# 3. CloudFront
module "cloudfront" {
  source              = "../../modules/cloudfront"
  name_prefix         = local.name_prefix
  domain_name         = var.domain_name
  alb_dns_name        = module.alb.alb_dns_name
  waf_acl_id          = module.waf.web_acl_arn
  acm_cert_arn        = aws_acm_certificate.edge_cert.arn # VIRGINIA CERT
  
  # Handshake
  secret_header_name  = local.header_name
  secret_header_value = local.header_value

  log_bucket_name     = module.s3_logs.bucket_id 
}

# 4. Registry 
module "dns" {
  source                    = "../../modules/dns"
  domain_name               = var.domain_name
  name_prefix               = local.name_prefix
  alias_dns_name            = module.cloudfront.distribution_domain_name
  alias_zone_id             = module.cloudfront.distribution_hosted_zone_id
  
  # Validates BOTH certificates in one Route53 Zone
  domain_validation_options = concat(
    tolist(aws_acm_certificate.edge_cert.domain_validation_options),
    tolist(aws_acm_certificate.origin_cert.domain_validation_options)
  )
}

######################################################################################
# PHASE 5: STATE METADATA
######################################################################################

resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/lab/db/endpoint"
  type  = "String"
  value = module.rds.rds_endpoint
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/lab/db/port"
  type  = "String"
  value = "3306"
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/lab/db/name"
  type  = "String"
  value = local.db_name
}