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
  public_subnet_cidr_2  = var.public_subnet_cidr_2
  private_subnet_cidr_1 = var.private_subnet_cidr_1
  private_subnet_cidr_2 = var.private_subnet_cidr_2
  env_prefix            = local.name_prefix
  avail_zone_1          = var.avail_zone_1
  avail_zone_2          = var.avail_zone_2
  rtb_public_cidr       = var.rtb_public_cidr

}

######################################################################################

module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"

  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  private_route_table_id = module.vpc.private_route_table_id
  region                 = var.region

  endpoint_sg_id = module.security.vpce_endpoints_sg_id
}

######################################################################################

module "security" {
  source = "../../modules/security"

  name_prefix = local.name_prefix

  vpc_id          = module.vpc.vpc_id
  env_prefix      = local.name_prefix
  alb_to_ec2_port = var.app_port
  tcp_ingress_rule = {
    port        = 3306
    description = "MySQL access from EC2"
  }
}

######################################################################################
module "ec2" {
  source     = "../../modules/ec2"
  env_prefix = local.name_prefix
  # Isolated EC2 from public subnet.

  #subnet_id             = module.vpc.public_subnet_id

  # This will place EC2 in private subnet A.
  subnet_id = module.vpc.private_subnet_ids[0]

  instance_type         = var.instance_type
  security_group_ids    = [module.security.ec2_sg_id]
  instance_profile_name = module.iam.instance_profile_name
}

######################################################################################
module "iam" {
  source      = "../../modules/iam"
  region      = var.region
  account_id  = var.account_id
  env_prefix  = local.name_prefix
  kms_key_arn = var.kms_key_arn
}

######################################################################################
module "rds" {
  source = "../../modules/rds"

  # Credentials dynamically pulled from Secrets Manager
  db_username = local.rds_secret.username
  db_password = local.rds_secret.password
  db_name     = local.normalized_db_name

  # This is set to true for Lab 1B, false for troubleshooting and cost savings.
  multi_az = var.rds_multi_az

  db_subnet_group_name  = module.vpc.db_subnet_group_name
  rds_security_group_id = module.security.rds_sg_id
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

  email_addresses = [var.alert_email]
  tags = merge(var.tags, {
    Module = "cloudwatch"
    Lab    = "incident-response"
  })
}

######################################################################################

module "config_store" {
  source = "../../modules/config-store"

  db_endpoint = local.rds_secret.host
  db_port     = local.rds_secret.port
  db_name     = local.normalized_db_name
  db_username = local.rds_secret.username
  db_password = local.rds_secret.password

  tags = local.tags
}

######################################################################################
# Lambda_Rotation Module

module "lambda_rotation" {
  source = "../../modules/lambda_rotation"

  engine        = "mysql"
  stack_name    = "${var.env_prefix}-rotation-mysql"
  function_name = "${var.env_prefix}-rds-rotation-mysql"

  # REQUIRED by SAR template
  endpoint = local.rds_secret.host

  enable_vpc = true

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security.ec2_sg_id]

  tags = var.tags
}

######################################################################################

# Ingress module for ALB, ACM, Route53, WAF, and other related resources

module "ingress" {
  source = "../../modules/ingress"

  env_prefix = local.name_prefix

  region = var.region

  vpc_id = module.vpc.vpc_id

  # Public subnets for ALB

  public_subnet_ids = module.vpc.public_subnet_ids

  # Security group for ALB

  alb_sg_id = module.security.alb_sg_id

  # Target EC2 instance to register with ALB

  target_instance_id = module.ec2.ec2_id

  # Domain details for ACM + Route53

  domain_name = var.domain_name

  # Subdomain for the application 
  # e.g., if domain_name is example.com and app_subdomain is "app", 
  # the full domain will be app.example.com

  app_subdomain = var.app_subdomain

  # Whether to manage Route53 hosted zone and records in Terraform or externally

  dns_mode = var.dns_mode

  # If managing Route53 in Terraform, provide the hosted zone name (e.g., example.com)

  route53_hosted_zone_id = var.route53_hosted_zone_id


  # WAF logging configuration to CloudWatch Logs

  waf_log_destination = var.waf_log_destination

  # Retention period for WAF CloudWatch log group (days)

  waf_log_retention_days = var.waf_log_retention_days

  # Whether to enable sampled requests only logging for WAF

  enable_waf_sampled_requests_only = var.enable_waf_sampled_requests_only

  # CloudWatch Alarm SNS Topic ARN for ALB 5xx errors

  alarm_action_topic_arn = module.cloudwatch.sns_topic_arn

  # ALB 5xx error threshold configuration for CloudWatch Alarm
  # These variables define when the alarm should trigger based on the number of 5xx errors.

  alb_5xx_threshold          = var.alb_5xx_threshold
  alb_5xx_period_seconds     = var.alb_5xx_period_seconds
  alb_5xx_evaluation_periods = var.alb_5xx_evaluation_periods

  # Expanding on WAF logging configuration: In this case we add statement allowing
  # Terraform to manage the lifecycle of the WAF log group, including force destroy to ensure cleanup.

  # Reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group#force_destroy
  # Reference: WAF logging best practices recommend setting force_destroy to true for log groups to ensure that they are 
  # deleted when the stack is destroyed, preventing orphaned log groups and potential cost implications.
  # 
  # Reference: https://docs.aws.amazon.com/waf/latest/developerguide/logging.html # (see "Best practices for logging" section)

  # Reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration  
  # This is a critical configuration for WAF logging, as it ensures that the log group can be automatically deleted when the stack 
  # is destroyed, preventing orphaned log groups and potential cost implications.


  waf_logs_force_destroy = true

  tags = local.tags
}

