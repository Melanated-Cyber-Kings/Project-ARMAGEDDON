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

  rds_secret = jsondecode(
    data.aws_secretsmanager_secret_version.rds.secret_string
  )
}
