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
# Secrets Manager (read existing secret created by bootstrap)
######################################################################################

data "aws_secretsmanager_secret" "rds" {
  name = var.db_secret_name
}

data "aws_secretsmanager_secret_version" "rds" {
  secret_id = data.aws_secretsmanager_secret.rds.id
}

# Decode JSON payload from Secrets Manager
locals {
  rds_secret = jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)
}

######################################################################################
# VPC / Network Module
######################################################################################

module "vpc" {
  source = "../../modules/network"

  vpc_cidr_block        = var.vpc_cidr_block
  public_subnet_cidr    = var.public_subnet_cidr
  private_subnet_cidr_1 = var.private_subnet_cidr_1
  private_subnet_cidr_2 = var.private_subnet_cidr_2

  env_prefix      = local.name_prefix
  avail_zone_1    = var.avail_zone_1
  avail_zone_2    = var.avail_zone_2
  rtb_public_cidr = var.rtb_public_cidr
}

######################################################################################
# Security (two SGs: EC2 + RDS, DB port is variable)
######################################################################################

module "security" {
  source     = "../../modules/security"
  vpc_id     = module.vpc.vpc_id
  env_prefix = local.name_prefix
  tags       = local.tags

  db_port = var.db_port
}

######################################################################################
# IAM (instance profile for EC2 to read the DB secret)
######################################################################################

module "iam" {
  source     = "../../modules/iam"
  region     = var.region
  account_id = var.account_id

  env_prefix  = local.name_prefix
  kms_key_arn = var.kms_key_arn

  # Least-privilege: scope to exactly one secret
  secret_arn = data.aws_secretsmanager_secret.rds.arn
}

######################################################################################
# RDS (private DB) — credentials pulled from Secrets Manager
######################################################################################

module "rds" {
  source = "../../modules/rds"

  env_prefix = local.name_prefix
  tags       = local.tags

  db_username = local.rds_secret.username
  db_password = local.rds_secret.password
  db_name     = local.rds_secret.dbname

  db_subnet_group_name  = module.vpc.db_subnet_group_name
  rds_security_group_id = module.security.rds_sg_id
}

######################################################################################
# EC2 (public app host)
######################################################################################

module "ec2" {
  source     = "../../modules/ec2"
  env_prefix = local.name_prefix
  tags       = local.tags

  subnet_id          = module.vpc.public_subnet_id
  instance_type      = var.instance_type
  security_group_ids = [module.security.ec2_sg_id]
  key_name           = var.key_name

  instance_profile_name = module.iam.instance_profile_name
}
