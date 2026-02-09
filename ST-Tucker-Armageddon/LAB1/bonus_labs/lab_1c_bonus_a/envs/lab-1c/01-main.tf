###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: environment
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

provider "aws" {
  region = var.region
}

######################################################################################
# VPC / Network Module

module "vpc" {
  source = "../../modules/network"

  vpc_cidr_block        = var.vpc_cidr_block
  public_subnet_cidr    = var.public_subnet_cidr
  private_subnet_cidr_1 = var.private_subnet_cidr_1
  private_subnet_cidr_2 = var.private_subnet_cidr_2
  env_prefix            = local.name_prefix
  avail_zone_1          = var.avail_zone_1
  avail_zone_2          = var.avail_zone_2
  rtb_public_cidr       = var.rtb_public_cidr
}

######################################################################################
# Security Module

module "security" {
  source     = "../../modules/security"
  vpc_id     = module.vpc.vpc_id
  env_prefix = local.name_prefix

  tcp_ingress_rule = {
    port        = 3306
    description = "MySQL access from EC2"
  }

  tags = var.tags
}

######################################################################################
# VPC Endpoints Module

module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"

  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  private_route_table_id = module.vpc.private_route_table_id
  ec2_sg_id              = module.security.ec2_sg_id
  region                 = var.region

  vpce_security_group_ids = [module.security.vpce_sg_id]

  # enable_kms_endpoint = true  # optional, keep false unless you want it
}

######################################################################################
# EC2 Module

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
# IAM Module

module "iam" {
  source      = "../../modules/iam"
  region      = var.region
  account_id  = var.account_id
  env_prefix  = local.name_prefix
  kms_key_arn = var.kms_key_arn
}

######################################################################################
# RDS Module

module "rds" {
  source = "../../modules/rds"

  # Credentials dynamically pulled from Secrets Manager (normalized locals)
  db_username = local.rds_username
  db_password = local.rds_password
  db_name     = local.rds_db_name

  multi_az = var.rds_multi_az

  db_subnet_group_name  = module.vpc.db_subnet_group_name
  rds_security_group_id = module.security.rds_sg_id
}

######################################################################################
# Reference the existing RDS secret

data "aws_secretsmanager_secret" "rds" {
  name = "lab-1c/rds/mysql"
}

data "aws_secretsmanager_secret_version" "rds" {
  secret_id = data.aws_secretsmanager_secret.rds.id
}

######################################################################################
# CloudWatch / SNS

module "cloudwatch" {
  source = "../../modules/cloudwatch"

  email_addresses = [var.alert_email]
  tags = merge(var.tags, {
    Module = "cloudwatch"
    Lab    = "incident-response"
  })
}

######################################################################################
# Parameter Store (Config Store)

module "config_store" {
  source = "../../modules/config-store"

  db_endpoint = local.rds_host
  db_port     = local.rds_port
  db_name     = local.rds_db_name
  db_username = local.rds_username
  db_password = local.rds_password

  tags = local.tags
}

######################################################################################
# Lambda Rotation Module

module "lambda_rotation" {
  source = "../../modules/lambda_rotation"

  engine        = "mysql"
  stack_name    = "${var.env_prefix}-rotation-mysql"
  function_name = "${var.env_prefix}-rds-rotation-mysql"

  # REQUIRED by SAR template
  endpoint = local.rds_host

  enable_vpc = true

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security.ec2_sg_id]

  tags = var.tags
}
