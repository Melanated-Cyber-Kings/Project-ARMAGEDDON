# Generate the 32-character "Secret Handshake" value
resource "random_password" "origin_handshake" {
  length  = 32
  special = false
}

locals {
  # Standardized Naming Convention
  name_prefix = lower("${var.project}-${var.env_prefix}")

  # Origin Cloaking Handshake (Used in CF Origin and ALB Rules)
  header_name  = "X-Origin-Secret"
  header_value = random_password.origin_handshake.result

  # Decode the JSON secret from the Secrets Manager Catalog
  # NOTE: This assumes 'data.aws_secretsmanager_secret_version.rds' exists in 01-main.tf
  rds_secret = jsondecode(
    data.aws_secretsmanager_secret_version.rds.secret_string
  )

  # Standardized Tags for every resource
  tags = {
    Project     = var.project
    Environment = var.env_prefix
    ManagedBy   = "Terraform"
    Security    = "Cloaked-Origin"
  }

  db_name = "labdb" 
}