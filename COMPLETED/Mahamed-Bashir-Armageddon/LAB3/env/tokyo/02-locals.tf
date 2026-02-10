# Generate 32-character "Secret Handshake" value
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

  # Decoded from Secrets Manager JSON
  rds_secret = jsondecode(
    data.aws_secretsmanager_secret_version.rds.secret_string
  )

   tags = {
    Project     = var.project
    Environment = var.env_prefix
    Region      = "Tokyo-Data-Authority"
    ManagedBy   = "Terraform"
  }

  db_name = "labdb" 
}