###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: environment
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

######################################################################################
# Network
######################################################################################
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

module "security" {
  source = "../../modules/security"

  #name_prefix = local.name_prefix
  vpc_id     = module.vpc.vpc_id
  env_prefix = local.name_prefix

  alb_to_ec2_port = var.app_port

  tcp_ingress_rule = {
    port        = 3306
    description = "MySQL access from EC2"
  }

  # ALB ingress rule is added by the module, but we need to pass the 
  # port for the description.
  # Note: the ALB security group is created in the ALB module, 
  # but we need to pass the port for the description.

  # direct ALB -> 403 from listener, but allows us to avoid creating 
  # an ALB security group dependency in the EC2 module.
  alb_ingress_mode = "cloudfront_prefix_list"
  #alb_ingress_mode = "public_443"

  # If you want to allow HTTP on port 80, you can 
  # set alb_allow_http_80 to true and the module will add 
  # an ingress rule to allow HTTP traffic on port 80 to the ALB security group. 
  # This is useful if you want to allow both HTTP and HTTPS traffic to your ALB.
  # alb_allow_http_80 = true
  alb_allow_http_80 = true


  tags = local.tags
}

module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"

  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  private_route_table_id = module.vpc.private_route_table_id
  region                 = var.region

  endpoint_sg_id = module.security.vpce_endpoints_sg_id
  #tags           = local.tags
}

######################################################################################
# IAM + Compute
######################################################################################
module "iam" {
  source      = "../../modules/iam"
  region      = var.region
  account_id  = var.account_id
  env_prefix  = local.name_prefix
  kms_key_arn = var.kms_key_arn
  tags        = local.tags
}

module "ec2" {
  source     = "../../modules/ec2"
  env_prefix = local.name_prefix

  # Place EC2 in private subnet A
  subnet_id = module.vpc.private_subnet_ids[0]

  instance_type         = var.instance_type
  security_group_ids    = [module.security.ec2_sg_id]
  instance_profile_name = module.iam.instance_profile_name
  tags                  = local.tags
}

######################################################################################
# Data plane: RDS
######################################################################################
module "rds" {
  source = "../../modules/rds"

  db_username = var.db_username
  db_password = var.db_password
  db_name     = var.db_name

  multi_az = var.rds_multi_az

  db_subnet_group_name  = module.vpc.db_subnet_group_name
  rds_security_group_id = module.security.rds_sg_id

  tags = local.tags
}

######################################################################################
# Rotation Lambda (SAR wrapper) - required for grading gates when enable_rotation=true
######################################################################################
module "lambda_rotation" {
  source = "../../modules/lambda_rotation"

  engine        = "mysql"
  stack_name    = "${local.name_prefix}-rotation-mysql"
  function_name = "${local.name_prefix}-rds-rotation-mysql"

  # REQUIRED by SAR template
  endpoint = module.rds.address

  enable_vpc = true

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security.ec2_sg_id]

  tags = local.tags
}

######################################################################################
# Secrets Manager (module)
# - Creates the secret if missing in this region/account
# - Optionally writes SecretString (manage_secret_value)
# - Optionally attaches rotation schedule (enable_rotation)
######################################################################################
module "secrets" {
  source = "../../modules/secrets"

  region     = var.region
  env_prefix = local.name_prefix

  username = var.db_username
  password = var.db_password
  dbname   = var.db_name

  address = module.rds.address
  port    = var.db_port

  manage_secret_value = var.manage_secret_value

  enable_rotation     = var.enable_rotation
  rotation_days       = var.rotation_days
  rotation_lambda_arn = module.lambda_rotation.rotation_lambda_arn

  tags = local.tags

  depends_on = [module.lambda_rotation]
}

######################################################################################
# Observability + Parameter Store
######################################################################################
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  email_addresses = [var.alert_email]
  tags = merge(local.tags, {
    Module = "cloudwatch"
    Lab    = "incident-response"
  })
}

module "config_store" {
  source = "../../modules/config-store"

  db_endpoint = module.rds.address
  db_port     = var.db_port
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  tags = local.tags
}
