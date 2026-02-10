provider "aws" {                                       
    region = var.region        
}

#for cloudfront
# provider "aws" {
#   alias  = "global"
#   region = "us-east-1"
# }

# provider "aws" {
#   alias  = "acm"
#   region = "us-east-1"
# }

# # ADD THIS for WAF CloudFront
# provider "aws" {
#   alias  = "waf"
#   region = "us-east-1"
# }

# provider "aws" {
# alias = "doit"
# region = "us-east-1"

# }

######################################################################################
# VPC / Network Module

module "vpc" {
  source = "../../modules/network"

  vpc_cidr_block  = var.vpc_cidr_block
  public_subnet_cidr  = var.public_subnet_cidr
  public_subnet_cidr2 = var.public_subnet_cidr2
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
  project = var.project
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
  #lab1c no more public
  #subnet_id          = module.vpc.public_subnet_id

  subnet_id          = module.vpc.private_subnet_id
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
  aws_cli_username =  var.aws_cli_username
  zone_id = module.alb_waf.zone_id
}

######################################################################################
module "rds" {
  source = "../../modules/rds"

# Credentials dynamically pulled from Secrets Manager
  db_username            = local.rds_secret.username
  db_password            = local.rds_secret.password
  db_name                = local.rds_secret.db_name

  db_subnet_group_name   = module.vpc.db_subnet_group_name
  rds_security_group_id  = module.security.rds_sg_id
}
######################################################################################
# Reference the existing RDS secret

# This is the data block Terraform “sees” and evaluates during terraform plan and terraform apply:
# Fetches the *current version* of an existing secret from AWS Secrets Manager
# This does NOT create the secret
# This makes a live AWS API call during plan/apply
data "aws_secretsmanager_secret" "rds" {
  name = "lab/rds/mysql"
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

######################################################################################
module "cloudwatch" {
  source = "../../modules/cloudwatch"
  
  alert_email = var.alert_email
  project = var.project
  env_prefix  = local.name_prefix
  region = var.region
  arn_suffix = module.alb_waf.arn_suffix

  tags = merge(var.tags, {
    Module   = "cloudwatch"
    Lab      = "incident-response"
  })
}

######################################################################################

module "config_store" {
  source = "../../modules/config-store"
  
  db_endpoint = module.rds.address
  db_port     = local.rds_secret.port
  db_name     = local.rds_secret.db_name
  db_username = local.rds_secret.username
  db_password = local.rds_secret.password
  
  tags = local.tags
}

######################################################################################
module "endpoints" {
  source = "../../modules/endpoints"

  vpc_id    = module.vpc.vpc_id
  env_prefix         = local.name_prefix
  private_subnet_ids  = module.vpc.private_subnet_ids
  security_group_ids  = [module.security.vpc_end_sg_id] 

  private_route_table_id = module.vpc.private_route_table_id
  secrets_lambda_sg_id = module.security.lambda_to_secrets_id
}

######################################################################################

module "zone53" {
  source = "../../modules/zone53"

  domain_name = var.domain_name
  project = var.project
  env_prefix  = local.name_prefix

  subdomain = var.app_subdomain
  zone_id = module.alb_waf.zone_id
  alb_dns_name = module.alb_waf.lb_dns_name

}

######################################################################################
module "targetgroup" {
  source = "../../modules/targetgroup"

  vpc_id    = module.vpc.vpc_id
  project = var.project
  env_prefix  = local.name_prefix

  ec2_id  = module.ec2.ec2_id

}

######################################################################################

module alb_waf {
source = "../../modules/alb_waf"

target_group_arn = module.targetgroup.target_group_arn
certificate_arn = module.zone53.certificate_arn
alb_sg_id = module.security.alb_sg_id
public_subnet_ids = [module.vpc.public_subnet_id, module.vpc.public_subnet2_id]

vpc_id    = module.vpc.vpc_id
project = var.project
env_prefix  = local.name_prefix

enable_alb_access_logs = var.enable_alb_logs

header_value = module.cloudfront.header_value

}

######################################################################################


module rotation {
source = "../../modules/rotation"

  region = var.region
  env_prefix         = local.name_prefix
  private_subnet_ids = module.vpc.private_subnet_ids
  lambda_security_group_ids =  [module.security.lambda_to_rds_id, module.security.lambda_to_secrets_id]
  secret_id = module.config_store.secret_id

}




######################################################################################
module cloudfront {
source = "../../modules/cloudfront"

#cloudfront lives on us-east-1
#Alias for Virginia (WAF/Edge Cert)
# providers = {
#   aws = aws.doit
# }


  project = var.project
  
  #env_prefix  = local.name_prefix

  subdomain = var.app_subdomain
  domain_name = var.domain_name
  alb_dns_name = module.alb_waf.lb_dns_name
  targetgroup_arn = module.targetgroup.target_group_arn
  zone_id = module.zone53.Z53zone_id
  waf_arn = module.alb_waf.waf_arn
  
}