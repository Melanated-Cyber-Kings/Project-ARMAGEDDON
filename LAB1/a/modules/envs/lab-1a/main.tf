provider "aws" {                                       
    region = var.region        
}

# VPC / Network Module

module "vpc" {
  source = "../../network"

  vpc_cidr_block  = var.vpc_cidr_block
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  env_prefix      = local.name_prefix
  avail_zone = var.avail_zone
  rtb_public_cidr = var.rtb_public_cidr  # ✅ THIS LINE FIXES IT

}

# Reference the existing RDS secret
data "aws_secretsmanager_secret" "rds" {
  name = "lab-1a/rds/mysql"
}


