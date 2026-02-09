###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: secrets
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

provider "aws" {
  region = var.region
}

# ============================================================
# Secrets Manager — RDS Credentials
# ============================================================

resource "aws_secretsmanager_secret" "this" {
  name        = var.secret_name
  description = var.description
  kms_key_id  = var.kms_key_arn

  tags = {
    Project = "Armageddon"
    Lab     = "LAB1A"
    Managed = "Terraform"
  }
}

# ------------------------------------------------------------
# Initial Secret Version
# ------------------------------------------------------------

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id

  secret_string = jsonencode({
    username = var.rds_username
    password = var.rds_password
    address  = var.address
    port     = var.port
    dbname   = var.db_name
  })
}

# ------------------------------------------------------------
# Rotation (Optional)
# ------------------------------------------------------------

resource "aws_secretsmanager_secret_rotation" "this" {
  count = var.rotation_lambda_arn == null ? 0 : 1

  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = 30
  }
}
