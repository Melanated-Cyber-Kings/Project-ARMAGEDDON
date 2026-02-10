locals {
  name_prefix = lower("${var.project}-${var.env_prefix}")

  instance_type_by_env = {
    lab1a = "t3.micro"
    lab1b = "t3.micro"
    lab2  = "t3.micro"
  }

  tags = {
    Environment = var.env_prefix
    ManagedBy   = "Terraform"
  }

  # HA Configuration
  ha_availability_zones   = ["ap-northeast-1a", "ap-northeast-1c"]
  ha_public_subnet_cidrs  = ["172.17.1.0/24", "172.17.2.0/24"]
  ha_private_subnet_cidrs = ["172.17.11.0/24", "172.17.12.0/24"]

  # Direct RDS credentials (bypassing Secrets Manager for now)
  rds_secret = {
    username = var.db_username
    password = var.db_password
    dbname   = var.db_name
  }
}
