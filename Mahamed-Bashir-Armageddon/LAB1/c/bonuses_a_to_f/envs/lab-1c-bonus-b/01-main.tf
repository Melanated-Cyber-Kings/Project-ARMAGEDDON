######################################################################################
# Provider Config
######################################################################################

provider "aws" {                                       
    region = var.region        
}

######################################################################################
# Network Module
######################################################################################
module "vpc" {
  source = "../../modules/network"
  vpc_cidr_block           = var.vpc_cidr_block
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_subnet_cidrs_app = var.private_subnet_cidrs_app
  private_subnet_cidrs_db  = var.private_subnet_cidrs_db
  azs                      = var.avail_zones
  name_prefix               = local.name_prefix
  rtb_public_cidr          = var.rtb_public_cidr
  

}

######################################################################################
# Security Groups Module
######################################################################################
module "security" {
  source    = "../../modules/security"
  vpc_id    = module.vpc.vpc_id
  name_prefix = local.name_prefix
  tcp_ingress_rule = {
    port        = 3306
    description = "MySQL access from EC2"
  }
}
######################################################################################
# Compute/EC2 Module
######################################################################################
module "ec2" {
  source             = "../../modules/ec2"
  name_prefix         = local.name_prefix
  subnet_id          = module.vpc.private_app_subnet_ids[0] 
  instance_type      = var.instance_type
  security_group_ids = [module.security.ec2_sg_id]
  region             = var.region
  instance_profile_name = module.iam.instance_profile_name
  
  #Injected variables into user_data script
  user_data = templatefile("${path.module}/user_data.sh", {
    region          = var.region
    secret_id       = var.db_secret_name
  })
}
######################################################################################
# IAM Module 
######################################################################################
module "iam" {
  source     = "../../modules/iam"
  region     = var.region
  account_id = var.account_id
  name_prefix = local.name_prefix  
}

######################################################################################
# RDS Module
######################################################################################
module "rds" {
  source = "../../modules/rds"


  db_username            = local.rds_secret.username
  db_password            = local.rds_secret.password
  db_name                = local.rds_secret.dbname
  db_subnet_group_name   = module.vpc.db_subnet_group_name
  rds_security_group_id  = module.security.rds_sg_id
}

######################################################################################
# Store RDS connection info in SSM Parameters for EC2 retrieval
######################################################################################



data "aws_secretsmanager_secret" "rds" {
  name = var.db_secret_name
}
#
data "aws_secretsmanager_secret_version" "rds" {
  secret_id = data.aws_secretsmanager_secret.rds.id
}

# SSM Parameters to store RDS connection info
resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/lab/db/endpoint"
  type  = "String"
  value = replace(module.rds.rds_endpoint, ":3306", "") 
}
resource "aws_ssm_parameter" "db_port" {
  name  = "/lab/db/port"
  type  = "String"
  value = "3306"
}
resource "aws_ssm_parameter" "db_name" {
  name  = "/lab/db/name"
  type  = "String"
  value = "labdb"
}