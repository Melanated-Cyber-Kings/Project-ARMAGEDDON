terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket         = "armageddon-tf-state-tokyo"
    key            = "lab3/tokyo.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
  }
}


# ----------------------------------------------------------------------------
# 1. DATA SOURCES: IDENTITY & REMOTE STATE
# ----------------------------------------------------------------------------


data "aws_secretsmanager_secret" "rds" {
  name = var.db_secret_name 
}

data "aws_secretsmanager_secret_version" "rds" {
  secret_id = data.aws_secretsmanager_secret.rds.id
}

# Read Sao Paulo Spoke state to retrieve TGW ID for peering and ALB for failover
data "terraform_remote_state" "saopaulo" {
  backend = "s3"
  config = {
    bucket = "armageddon-tf-state-saopaulo"
    key    = "lab3/saopaulo.tfstate"
    region = "sa-east-1"
  }
}

# ----------------------------------------------------------------------------
# 2. NETWORK FOUNDATION
# ----------------------------------------------------------------------------
module "vpc" {
  source                   = "../../modules/network"
  vpc_cidr_block           = var.vpc_cidr_block
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_subnet_cidrs_app = var.private_subnet_cidrs_app
  private_subnet_cidrs_db  = var.private_subnet_cidrs_db
  azs                      = var.avail_zones
  name_prefix              = local.name_prefix
  rtb_public_cidr          = var.rtb_public_cidr
  
  # Route cross-region traffic to the local TGW
  tgw_route_config = {
    destination_cidr = var.remote_spoke_cidr 
    tgw_id           = module.tgw_hub.tgw_id
  }
}

# ----------------------------------------------------------------------------
# 3. TRANSIT GATEWAY HUB
# ----------------------------------------------------------------------------
module "tgw_hub" {
  source      = "../../modules/tgw"
  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_app_subnet_ids
  
  is_requester = true
  peer_region  = "sa-east-1"
  
  # Resolve Spoke ID from remote state once initialized, otherwise null
  peer_tgw_id  = try(data.terraform_remote_state.saopaulo.outputs.tgw_id, null)
  remote_cidr  = var.remote_spoke_cidr
}

# ----------------------------------------------------------------------------
# 4. DATABASE
# ----------------------------------------------------------------------------
module "rds" {
  source                = "../../modules/rds"
  db_name               = local.db_name
  db_username           = local.rds_secret.username
  db_password           = local.rds_secret.password
  db_subnet_group_name  = module.vpc.db_subnet_group_name
  rds_security_group_id = module.security.rds_sg_id
}

# ----------------------------------------------------------------------------
# 5. COMPUTE & SECURITY
# ----------------------------------------------------------------------------
module "security" {
  source      = "../../modules/security"
  vpc_id      = module.vpc.vpc_id
  name_prefix = local.name_prefix
  
  # Module requires port definition; ingress not used in stateless spoke.
  tcp_ingress_rule = {
    port        = 3306
    description = "MySQL access"
  }

  # Allow cross-region ingress from Spoke VPC CIDR via Transit Gateway
  allow_remote_cidr = var.remote_spoke_cidr 
}

module "iam" {
  source      = "../../modules/iam"
  region      = var.region
  account_id  = var.account_id
  name_prefix = local.name_prefix
}

module "ec2" {
  source                     = "../../modules/ec2"
  name_prefix                = local.name_prefix
  private_app_subnet_ids     = module.vpc.private_app_subnet_ids
  target_group_arn_for_asg   = module.alb.target_group_arn
  subnet_id                  = module.vpc.private_app_subnet_ids[0]
  instance_type              = var.instance_type
  security_group_ids         = [module.security.ec2_sg_id]
  region                     = var.region
  instance_profile_name      = module.iam.instance_profile_name
  public_ip                  = false
  
  user_data = templatefile("user_data.sh", {
    region    = var.region
    secret_id = var.db_secret_name
  })
}

# ----------------------------------------------------------------------------
# 6. GLOBAL EDGE UPGRADE (ALB + CloudFront)
# ----------------------------------------------------------------------------
module "s3_logs" {
  source      = "../../modules/s3"
  bucket_name = "${local.name_prefix}-alb-logs-${var.account_id}"
  name_prefix = local.name_prefix
  account_id  = var.account_id
}

module "waf" {
  source      = "../../modules/waf"
  name_prefix = local.name_prefix
  providers   = { aws = aws.us_east_1 } # Explicit Provider Handshake
}

module "alb" {
  source             = "../../modules/alb"
  name_prefix        = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_ids = [module.security.alb_sg_id]
 
  
  access_logs_bucket = module.s3_logs.bucket_id
  certificate_arn    = aws_acm_certificate.origin_cert.arn
  
  header_name        = local.header_name
  header_value       = local.header_value
}

module "cloudfront" {
  source              = "../../modules/cloudfront"
  name_prefix         = local.name_prefix
  domain_name         = var.domain_name
  alb_dns_name        = module.alb.alb_dns_name
  waf_acl_id          = module.waf.web_acl_arn
  acm_cert_arn        = aws_acm_certificate.edge_cert.arn
  log_bucket_name     = module.s3_logs.bucket_id
  secret_header_name  = local.header_name
  secret_header_value = local.header_value

  # Configure Origin Group for global failover if Spoke ALB is available
  secondary_alb_dns_name = try(data.terraform_remote_state.saopaulo.outputs.alb_dns_name, null)
}

module "dns" {
  source                    = "../../modules/dns"
  domain_name               = var.domain_name
  name_prefix               = local.name_prefix
  alias_dns_name            = module.cloudfront.distribution_domain_name
  alias_zone_id             = module.cloudfront.distribution_hosted_zone_id

  # Aggregate validation records for Edge, Hub, and Spoke certificates
  domain_validation_options = concat(
    tolist(aws_acm_certificate.edge_cert.domain_validation_options),
    tolist(aws_acm_certificate.origin_cert.domain_validation_options),
    try(tolist(data.terraform_remote_state.saopaulo.outputs.saopaulo_cert_validation_options), [])
  )
}