###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: environment
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

# Need to set the required provider version here to avoid conflicts with 
# the secrets module, which also uses the AWS provider.

# Encountered issues where the secrets module requires a newer version of the AWS provider,
# but the root module (lab-1c) has an older version constraint, causing a version conflict.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region = var.region
}

######################################################################################
# VPC / Network Module
######################################################################################

module "vpc" {
  source = "../../modules/network"

  vpc_cidr_block        = var.vpc_cidr_block
  public_subnet_cidr    = var.public_subnet_cidr
  public_subnet_cidr_2  = var.public_subnet_cidr_2
  private_subnet_cidr_1 = var.private_subnet_cidr_1
  private_subnet_cidr_2 = var.private_subnet_cidr_2
  env_prefix            = local.name_prefix
  avail_zone_1          = var.avail_zone_1
  avail_zone_2          = var.avail_zone_2
  rtb_public_cidr       = var.rtb_public_cidr
}

######################################################################################
# Security Groups
######################################################################################

module "security" {
  source = "../../modules/security"

  name_prefix = local.name_prefix

  vpc_id          = module.vpc.vpc_id
  env_prefix      = local.name_prefix
  alb_to_ec2_port = var.app_port

  tcp_ingress_rule = {
    port        = 3306
    description = "MySQL access from EC2"
  }
}

######################################################################################
# VPC Endpoints (for private subnet access to AWS APIs)
######################################################################################

module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"

  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  private_route_table_id = module.vpc.private_route_table_id
  region                 = var.region

  endpoint_sg_id = module.security.vpce_endpoints_sg_id
}

######################################################################################
# IAM (EC2 role/profile, KMS permissions, etc.)
######################################################################################

module "iam" {
  source      = "../../modules/iam"
  region      = var.region
  account_id  = var.account_id
  env_prefix  = local.name_prefix
  kms_key_arn = var.kms_key_arn
}

######################################################################################
# EC2 (App Host)
######################################################################################

module "ec2" {
  source     = "../../modules/ec2"
  env_prefix = local.name_prefix

  # Place EC2 in private subnet A
  subnet_id = module.vpc.private_subnet_ids[0]

  instance_type         = var.instance_type
  security_group_ids    = [module.security.ec2_sg_id]
  instance_profile_name = module.iam.instance_profile_name
}

######################################################################################
# RDS (Credentials are driven by env vars; secret is overwritten from Terraform)
######################################################################################

module "rds" {
  source = "../../modules/rds"

  db_username = var.db_username
  db_password = var.db_password
  db_name     = var.db_name

  multi_az = var.rds_multi_az

  db_subnet_group_name  = module.vpc.db_subnet_group_name
  rds_security_group_id = module.security.rds_sg_id
}

######################################################################################
# CloudWatch / SNS (alarms + notifications)
######################################################################################

module "cloudwatch" {
  source = "../../modules/cloudwatch"

  email_addresses = [var.alert_email]
  tags = merge(var.tags, {
    Module = "cloudwatch"
    Lab    = "incident-response"
  })
}

######################################################################################
# Lambda Rotation (SAR template wrapper)
# - Endpoint MUST come from the RDS module output (module.rds.address)
######################################################################################

module "lambda_rotation" {
  source = "../../modules/lambda_rotation"

  engine        = "mysql"
  stack_name    = "${var.env_prefix}-rotation-mysql"
  function_name = "${var.env_prefix}-rds-rotation-mysql"

  # REQUIRED by SAR template
  endpoint = module.rds.address

  enable_vpc = true

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security.ec2_sg_id]

  tags = var.tags
}

#################################################################################
# Secrets Manager (module)
# - If secret exists in AWS: reuse it and overwrite SecretString from Terraform
# - If secret missing: create it and write SecretString
# - Rotation enabled for grading when enable_rotation=true
#################################################################################

module "secrets" {
  source = "../../modules/secrets"

  region     = var.region
  env_prefix = var.env_prefix

  username = var.db_username
  password = var.db_password
  dbname   = var.db_name


  # Store the real DB endpoint in the secret payload
  address = module.rds.address
  port    = var.db_port

  enable_rotation     = var.enable_rotation
  rotation_days       = var.rotation_days
  rotation_lambda_arn = module.lambda_rotation.rotation_lambda_arn

  manage_secret_value = var.manage_secret_value

  tags = var.tags

  depends_on = [module.lambda_rotation]
}

######################################################################################
# Config Store (SSM Parameter Store)
######################################################################################

module "config_store" {
  source = "../../modules/config-store"

  db_endpoint = module.rds.address
  # db_port     = 3306
  db_port     = var.db_port
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  tags = local.tags
}

######################################################################################
# Ingress module for ALB, ACM, Route53, WAF, and other related resources
######################################################################################

module "ingress" {
  source = "../../modules/ingress"

  env_prefix = local.name_prefix
  region     = var.region

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id

  target_instance_id = module.ec2.ec2_id

  domain_name            = var.domain_name
  app_subdomain          = var.app_subdomain
  dns_mode               = var.dns_mode
  route53_hosted_zone_id = var.route53_hosted_zone_id

  waf_log_destination              = var.waf_log_destination
  waf_log_retention_days           = var.waf_log_retention_days
  enable_waf_sampled_requests_only = var.enable_waf_sampled_requests_only
  waf_logs_force_destroy           = true

  alarm_action_topic_arn = module.cloudwatch.sns_topic_arn

  alb_5xx_threshold          = var.alb_5xx_threshold
  alb_5xx_period_seconds     = var.alb_5xx_period_seconds
  alb_5xx_evaluation_periods = var.alb_5xx_evaluation_periods

  tags = local.tags
}
