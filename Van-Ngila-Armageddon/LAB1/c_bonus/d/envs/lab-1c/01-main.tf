provider "aws" {                                       
    region = var.region        
}
######################################################################################
# VPC / Network Module

module "vpc" {
  source = "../../modules/network"

  vpc_cidr_block  = var.vpc_cidr_block
  public_subnet_cidr_1 = var.public_subnet_cidr_1
  public_subnet_cidr_2 = var.public_subnet_cidr_2
  private_subnet_cidr_1 = var.private_subnet_cidr_1
  private_subnet_cidr_2 = var.private_subnet_cidr_2
  private_subnet_cidr_3 = var.private_subnet_cidr_3
  env_prefix      = local.name_prefix
  avail_zone_1 = var.avail_zone_1
  avail_zone_2 = var.avail_zone_2
  avail_zone_3 = var.avail_zone_3
  rtb_public_cidr = var.rtb_public_cidr
  alb_sg_id = module.security.alb_sg_id
  ec2_id = module.ec2.ec2_id
  acm_certificate_arn = module.dns.acm_certificate_arn

  enable_alb_access_logs = var.enable_alb_access_logs

  alb_access_logs_bucket_name = module.s3_logs.alb_logs_bucket_name
  alb_logs_bucket_dependency = module.s3_logs.alb_logs_bucket_id
  alb_access_logs_bucket_arn = module.s3_logs.alb_logs_bucket_arn

  alb_access_logs_prefix = var.alb_access_logs_prefix
}

######################################################################################

module "security" {
  source    = "../../modules/security"
  vpc_id    = module.vpc.vpc_id
  vpc_endpoint_sg_id = module.vpc_endpoints.vpc_endpoint_sg_id
  
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
  subnet_id          = element(module.vpc.private_subnet_ids, 0)
  instance_type      = var.instance_type
  security_group_ids  = [module.security.ec2_sg_id,module.security.vpc_endpoint_sg_id, module.security.alb_sg_id]
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
  name = "lab-1c/rds/mysql"
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
  
  region = var.region
  env_prefix = var.env_prefix
  alb_arn_suffix               = module.vpc.alb_arn_suffix  # Pass network output to cloudwatch
  alb_5xx_evaluation_periods   = var.alb_5xx_evaluation_periods
  alb_5xx_threshold            = var.alb_5xx_threshold
  alb_5xx_period_seconds       = var.alb_5xx_period_seconds

  email_addresses = [var.alert_email]  
  tags = merge(var.tags, {
    Module   = "cloudwatch"
    Lab      = "incident-response"
  })
}

######################################################################################

module "config_store" {
  source = "../../modules/config-store"
  
  db_endpoint = module.rds.db_endpoint
  db_port     = module.rds.db_port
  db_name     = module.rds.db_name
  db_username = local.rds_secret.username
  db_password = local.rds_secret.password  
  tags = local.tags
}

######################################################################################

module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"

  vpc_id              = module.vpc.vpc_id
  vpc_endpoint_sg_id  = module.security.vpc_endpoint_sg_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  route_table_ids     = module.vpc.private_route_table_ids
  region              = var.region
  env_prefix              = var.env_prefix
  enable_kms_endpoint = var.enable_kms_endpoint

  # Optional: Custom endpoint policy
  # endpoint_policy = jsonencode({
  #   Version = "2012-10-17"
  #   Statement = [...]
  # })
}

######################################################################################
module "dns" {
  source = "../../modules/dns"
  enable_waf = var.enable_waf
  env_prefix = var.env_prefix
  alb_arn    = module.vpc.alb_arn  
  alb_dns_name = module.vpc.alb_dns_name
  alb_zone_id = module.vpc.alb_zone_id
  domain_name = var.domain_name
  create_apex_record = var.create_apex_record

  # Optional: Skip if already validated
  create_validation_records = true
  wait_for_validation       = true
}

######################################################################################
module "s3_logs" {
  source = "../../modules/s3-logs"
  
  env_prefix              = var.env_prefix
  enable_alb_access_logs  = var.enable_alb_access_logs
  alb_access_logs_prefix = var.alb_access_logs_prefix
  account_id = var.account_id
}