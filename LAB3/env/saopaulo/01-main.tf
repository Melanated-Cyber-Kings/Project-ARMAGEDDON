terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket         = "armageddon-tf-state-saopaulo"
    key            = "lab3/saopaulo.tfstate"
    region         = "sa-east-1"
    encrypt        = true
  }
}

# ----------------------------------------------------------------------------
# 1. DATA SOURCES: SECRETS & REMOTE STATE
# ------------------------------ ----------------------------------------------
data "aws_secretsmanager_secret" "rds" {
  name = var.db_secret_name
}

data "aws_secretsmanager_secret_version" "rds" {
  secret_id = data.aws_secretsmanager_secret.rds.id
}


# Read Tokyo Hub state to retrieve RDS Endpoint and TGW Peering ID
data "terraform_remote_state" "tokyo" {
  backend = "s3"
  config = {
    bucket = "armageddon-tf-state-tokyo"
    key    = "lab3/tokyo.tfstate"
    region = "ap-northeast-1"
  }
}

# ----------------------------------------------------------------------------
# 2. NETWORK FOUNDATION (LIBERDADE)
# ----------------------------------------------------------------------------
module "vpc" {
  source                   = "../../modules/network"
  vpc_cidr_block           = var.vpc_cidr_block
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_subnet_cidrs_app = var.private_subnet_cidrs_app
  private_subnet_cidrs_db  = var.private_subnet_cidrs_db # EMPTY FOR COMPLIANCE
  azs                      = var.avail_zones
  name_prefix              = local.name_prefix
  rtb_public_cidr          = var.rtb_public_cidr

  # Route cross-region traffic to the local TGW
  tgw_route_config = {
    destination_cidr = var.remote_hub_cidr # 172.17.0.0/16
    tgw_id           = module.tgw_spoke.tgw_id
  }
}

# ----------------------------------------------------------------------------
# 3. TRANSIT GATEWAY SPOKE
# ----------------------------------------------------------------------------
module "tgw_spoke" {
  source      = "../../modules/tgw"
  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_app_subnet_ids
  
  is_requester = false
 # Handle cross-state dependency: Peering ID is null until Tokyo Pass 2 creates it.
  peering_attachment_id = try(data.terraform_remote_state.tokyo.outputs.peering_id, null)
  remote_cidr = var.remote_hub_cidr
}

# ----------------------------------------------------------------------------
# 4. COMPUTE & SECURITY
# ----------------------------------------------------------------------------
module "security" {
  source      = "../../modules/security"
  vpc_id      = module.vpc.vpc_id
  name_prefix = local.name_prefix
  
  # Module requires port definition; ingress not used in stateless spoke.
  tcp_ingress_rule = {
    port        = 3306
    description = "MySQL (Unused/Stateless)"
  }
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
# 5. REGIONAL GATEWAY (ALB)
# ----------------------------------------------------------------------------
module "s3_logs" {
  source      = "../../modules/s3"
  bucket_name = "${local.name_prefix}-alb-logs-${var.account_id}"
  name_prefix = local.name_prefix
  account_id  = var.account_id
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


# ----------------------------------------------------------------------------
# 6. CONFIGURATION BRIDGE
# ----------------------------------------------------------------------------
# Inject the Hub's RDS endpoint into the Spoke's SSM Parameter Store 

resource "aws_ssm_parameter" "db_endpoint" {
  name        = "/lab/db/endpoint"
  description = "Primary Database Endpoint (Hub)"
  type        = "String"
  value       = data.terraform_remote_state.tokyo.outputs.rds_endpoint
  tags        = local.tags
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/lab/db/name"
  description = "Database Name"
  type        = "String"
  value       = local.db_name
  tags        = local.tags
}

resource "aws_ssm_parameter" "db_port" {
  name        = "/lab/db/port"
  description = "Database Port"
  type        = "String"
  value       = "3306"
  tags        = local.tags
}