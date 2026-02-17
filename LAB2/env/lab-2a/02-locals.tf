# Generate the 32-character "Secret Handshake" value
resource "random_password" "origin_handshake" {
  length  = 32
  special = false
}

locals {

  name_prefix = lower("${var.project}-${var.env_prefix}")

  # Origin Cloaking Handshake
  header_name  = "X-Origin-Secret"
  header_value = random_password.origin_handshake.result

  
  rds_secret = jsondecode(
    data.aws_secretsmanager_secret_version.rds.secret_string
  )

  # Standardized Tags
  tags = {
    Project     = var.project
    Environment = var.env_prefix
    ManagedBy   = "Terraform"
    Security    = "Cloaked-Origin"
  }

  db_name = "labdb" 
}