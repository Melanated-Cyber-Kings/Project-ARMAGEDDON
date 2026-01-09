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
}
