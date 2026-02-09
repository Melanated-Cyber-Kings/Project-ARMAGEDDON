# Data Sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

module "network" {
  source = "./modules/network"

  project_name      = var.project_name
  environment       = var.environment
  availability_zone = "ap-northeast-1a" # Use first available AZ

  alb_security_group_id = aws_security_group.alb.id
}

# Database Module
module "database" {
  source = "./modules/database"

  project_name               = var.project_name
  environment                = var.environment
  db_name                    = var.db_name
  db_username                = var.db_username
  db_password                = var.db_password
  subnet_ids                 = module.network.private_subnet_ids # Pass as list
  database_security_group_id = module.network.database_security_group_id
  region                     = "ap-northeast-1"
  account_id                 = data.aws_caller_identity.current.account_id

  depends_on = [module.network]
}

# Secrets Module
module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name
  environment  = var.environment
  db_endpoint  = module.database.db_endpoint
  db_port      = module.database.db_port
  db_name      = module.database.db_name
  db_username  = var.db_username
  db_password  = var.db_password
  region       = "ap-northeast-1"
  account_id   = data.aws_caller_identity.current.account_id

  depends_on = [module.database]
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  project_name          = var.project_name
  environment           = var.environment
  ami_id                = data.aws_ami.ubuntu.id
  subnet_id             = module.network.public_subnet_id
  app_security_group_id = module.network.app_security_group_id
  key_name              = null
  region                = "ap-northeast-1"
  account_id            = data.aws_caller_identity.current.account_id
  kms_key_arn           = module.secrets.secrets_kms_key_arn

  depends_on = [module.network, module.secrets]
}

# Incident Response Module (create SNS topic first)
module "incident_response" {
  source = "./modules/incident-response"

  project_name   = var.project_name
  environment    = var.environment
  region         = "ap-northeast-1"
  account_id     = data.aws_caller_identity.current.account_id
  kms_key_arn    = module.secrets.secrets_kms_key_arn
  rds_secret_arn = module.secrets.rds_secret_arn
  db_instance_id = module.database.rds_instance_id

  depends_on = [module.database, module.secrets]
}

# Monitoring Module - create its own SNS topic for now
module "monitoring" {
  source = "./modules/monitoring"

  project_name    = var.project_name
  environment     = var.environment
  kms_key_arn     = module.secrets.secrets_kms_key_arn # REUSE existing KMS key
  db_instance_id  = module.database.rds_instance_id
  ec2_instance_id = module.compute.instance_id
  region          = "ap-northeast-1"
  account_id      = data.aws_caller_identity.current.account_id

  depends_on = [module.database, module.compute]
}