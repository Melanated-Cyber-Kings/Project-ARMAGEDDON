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
####################################################################### 
 


  # Decode the JSON secret into a usable Terraform object

  # RDS credentials pulled from Secrets Manager
  # This is How the Secret Value Becomes Usable in Terraform
  # The secret value is returned as a JSON string.
  # You must decode it:
  rds_secret = jsondecode(
    data.aws_secretsmanager_secret_version.rds.secret_string
  )
}

  # Now Terraform has access to:
  # local.rds_secret.username
  # local.rds_secret.password
  # local.rds_secret.dbname

  # Inside main.tf ""../../rds"