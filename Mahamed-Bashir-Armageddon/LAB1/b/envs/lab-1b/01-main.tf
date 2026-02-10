######################################################################################
# PHASE 1: PROVIDER BRIDGE & TERRAFORM CONFIG
######################################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# (Tokyo / Primary Region)
provider "aws" {
  region = var.region
}

# Global Provider
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

######################################################################################
# PHASE 2: DATA SOURCES & IDENTITY
######################################################################################


data "aws_secretsmanager_secret" "rds" {
  name = var.db_secret_name
}

data "aws_secretsmanager_secret_version" "rds" {
  secret_id = data.aws_secretsmanager_secret.rds.id
}


resource "aws_acm_certificate" "edge_cert" {
  provider          = aws.us_east_1 
  domain_name       = var.domain_name
  validation_method = "DNS"
  
  lifecycle { create_before_destroy = true }

  tags = local.tags
}

######################################################################################
# PHASE 3: REGIONAL FOUNDATION (LAB 1 MODULES)
######################################################################################

# 1. Networking (The Hyperlanes)
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

# 2. Identity (The EC2 Role)
module "iam" {
  source      = "../../modules/iam"
  region      = var.region
  account_id  = var.account_id
  name_prefix = local.name_prefix
}

# 3. Firewalls (The Security Groups)
module "security" {
  source      = "../../modules/security"
  vpc_id      = module.vpc.vpc_id
  name_prefix = local.name_prefix
  alb_sg_id   = module.security.alb_sg_id # Self-output for L2 logic
}

# 4. Compute (The Application Host)
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


module "rds" {
  source                = "../../modules/rds"
  db_name               = local.rds_secret.dbname
  db_username           = local.rds_secret.username
  db_password           = local.rds_secret.password
  db_subnet_group_name  = module.vpc.db_subnet_group_name
  rds_security_group_id = module.security.rds_sg_id
}


module "alb" {
  source             = "../../modules/alb"
  name_prefix        = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_ids = [module.security.alb_sg_id]
  target_id          = module.ec2.ec2_id
  
  
  header_name        = local.header_name
  header_value       = local.header_value
  https_listener_arn = module.alb.https_listener_arn 
  target_group_arn   = module.alb.target_group_arn
  

  access_logs_bucket = module.s3_logs.bucket_id 
  certificate_arn    = aws_acm_certificate.edge_cert.arn
}

module "waf_global" {
  source      = "../../modules/waf"
  name_prefix = local.name_prefix
  providers = {
    aws = aws.us_east_1
  }
}


module "cloudfront" {
  source              = "../../modules/cloudfront"
  name_prefix         = local.name_prefix
  alb_dns_name        = module.alb.alb_dns_name
  waf_acl_id          = module.waf_global.web_acl_arn
  acm_cert_arn        = aws_acm_certificate.edge_cert.arn
  domain_name         = var.domain_name
  
  
  secret_header_name  = local.header_name
  secret_header_value = local.header_value
}


module "dns" {
  source                    = "../../modules/dns"
  domain_name               = var.domain_name
  name_prefix               = local.name_prefix
  alias_dns_name            = module.cloudfront.distribution_domain_name
  alias_zone_id             = module.cloudfront.distribution_hosted_zone_id
  domain_validation_options = aws_acm_certificate.edge_cert.domain_validation_options
}


module "s3_logs" {
  source      = "../../modules/s3"
  bucket_name = "${local.name_prefix}-alb-logs-${var.account_id}"
  name_prefix = local.name_prefix
}