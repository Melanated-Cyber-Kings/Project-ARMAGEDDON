provider "aws" {                                       
    region = var.region        
}
######################################################################################
# VPC / Network Module

module "vpc" {
  source = "../../network"

  vpc_cidr_block  = var.vpc_cidr_block
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  env_prefix      = local.name_prefix
  avail_zone = var.avail_zone
  rtb_public_cidr = var.rtb_public_cidr  

}
######################################################################################

module "security" {
  source    = "../../security"
  vpc_id    = module.vpc.vpc_id
  env_prefix = local.name_prefix
  tcp_ingress_rule = {
    port        = 3306
    description = "MySQL access from EC2"
  }
}
######################################################################################
module "ec2" {
  source             = "../../ec2"
  env_prefix         = local.name_prefix
  subnet_id          = module.vpc.public_subnet_id
  instance_type      = var.instance_type
  security_group_ids  = [module.security.ec2_sg_id]
  instance_profile_name  = module.iam.instance_profile_name
}

######################################################################################
module "iam" {
  source     = "../../iam"
  region     = var.region
  account_id = var.account_id
  env_prefix = local.name_prefix
}

######################################################################################
module "rds" {
  source = "../../rds"

  db_username            = local.rds_secret.username
  db_password            = local.rds_secret.password
  db_name                = local.rds_secret.dbname
  db_subnet_group_name   = module.vpc.db_subnet_group_name
  rds_security_group_id  = module.security.rds_sg_id
}
######################################################################################








# Reference the existing RDS secret
data "aws_secretsmanager_secret" "rds" {
  name = "lab-1a/rds/mysql"
}

data "aws_secretsmanager_secret_version" "rds" {
  secret_id = data.aws_secretsmanager_secret.rds.id
}



