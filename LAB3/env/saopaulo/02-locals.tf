

locals {
  #Naming Convention
  name_prefix = lower("${var.project}-${var.env_prefix}")

  # Origin Cloaking Handshake
  header_name  = "X-Origin-Secret"
  header_value = data.terraform_remote_state.tokyo.outputs.origin_handshake_secret

  
  rds_secret = jsondecode(
    data.aws_secretsmanager_secret_version.rds.secret_string
  )

  tags = {
    Project     = var.project
    Environment = var.env_prefix
    Region      = "Sao-Paulo-Spoke"
    ManagedBy   = "Terraform"
  }

  db_name = "labdb" 
}