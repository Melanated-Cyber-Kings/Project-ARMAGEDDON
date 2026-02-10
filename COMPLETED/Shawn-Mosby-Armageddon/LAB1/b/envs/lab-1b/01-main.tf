provider "aws" {                                       
    region = var.region        
}
######################################################################################
# VPC / Network Module

module "vpc" {
  source = "../../modules/network"

  vpc_cidr_block  = var.vpc_cidr_block
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr_1 = var.private_subnet_cidr_1
  private_subnet_cidr_2 = var.private_subnet_cidr_2
  env_prefix      = local.name_prefix
  avail_zone_1 = var.avail_zone_1
  avail_zone_2 = var.avail_zone_2
  rtb_public_cidr = var.rtb_public_cidr  

}
######################################################################################

module "security" {
  source    = "../../modules/security"
  vpc_id    = module.vpc.vpc_id
  env_prefix = local.name_prefix
  tcp_ingress_rule = {
    port        = 3306
    description = "MySQL access from EC2"
  }
}
######################################################################################
module "ec2" {
  source             = "../../modules/ec2"
  env_prefix         = local.name_prefix
  subnet_id          = module.vpc.public_subnet_id
  instance_type      = var.instance_type
  security_group_ids  = [module.security.ec2_sg_id]
  instance_profile_name  = module.iam.instance_profile_name
}

######################################################################################
module "iam" {
  source     = "../../modules/iam"
  region     = var.region
  account_id = var.account_id
  env_prefix = local.name_prefix
  kms_key_arn = var.kms_key_arn
}

######################################################################################
module "rds" {
  source = "../../modules/rds"

# Credentials dynamically pulled from Secrets Manager
  db_username            = local.rds_secret.username
  db_password            = local.rds_secret.password
  db_name                = local.rds_secret.dbname

  db_subnet_group_name   = module.vpc.db_subnet_group_name
  rds_security_group_id  = module.security.rds_sg_id
}
######################################################################################
module "cloudwatch" {
  source = "../../modules/cloudwatch"
  
  email_addresses = [var.alert_email]  
  tags = merge(var.tags, {
    Module   = "cloudwatch"
    Lab      = "incident-response"
  })
}








# Reference the existing RDS secret

# This is the data block Terraform “sees” and evaluates during terraform plan and terraform apply:
# Fetches the *current version* of an existing secret from AWS Secrets Manager
# This does NOT create the secret
# This makes a live AWS API call during plan/apply
data "aws_secretsmanager_secret" "rds" {
  name = "lab-1a/rds/mysql"
}

#
# resource "aws_secretsmanager_secret_version" "rds" {
#   secret_id = data.aws_secretsmanager_secret.rds.id
# }

data "aws_secretsmanager_secret_version" "rds" {
  secret_id = data.aws_secretsmanager_secret.rds.id
  # secret_string = jsonencode({
  #   username = var.db_username
  #   password = var.db_password
  #   host     = var.address
  #   port     = var.port
  #   dbname   = var.db_name
  # })
}