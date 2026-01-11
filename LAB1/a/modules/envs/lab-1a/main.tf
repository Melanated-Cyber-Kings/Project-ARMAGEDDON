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










# Reference the existing RDS secret
data "aws_secretsmanager_secret" "rds" {
  name = "lab-1a/rds/mysql"
}





