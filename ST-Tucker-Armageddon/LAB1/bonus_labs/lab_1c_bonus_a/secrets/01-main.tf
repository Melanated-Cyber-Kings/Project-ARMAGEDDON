###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: secrets
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

# ============================================================
# Project: Armageddon — AWS Terraform Labs
# Lab:     1B
# Stack:   secrets
# File:    01-main.tf
#
# Purpose:
#   - Create an RDS credential secret in AWS Secrets Manager
#   - Optionally manage SecretString (manage_secret_value)
#   - Optionally enable rotation using a Lambda ARN constructed
#     from variables (rotation_lambda_account_id + rotation_lambda_name)
# ============================================================

provider "aws" {
  region = var.region
}

locals {
  # Secret name convention used in this lab
  secret_name = "${var.env_prefix}/rds/mysql"

  # Rotation enabled only if BOTH are set (non-null + non-empty)
  # rotation_enabled = (
  #   var.rotation_lambda_account_id != null &&
  #   var.rotation_lambda_name != null &&
  #   length(var.rotation_lambda_account_id) > 0 &&
  #   length(var.rotation_lambda_name) > 0
  # 
  # Added revised logic to only check for rotation_lambda_arn
  # Rotation enabled only when rotation_lambda_arn is provided
  rotation_enabled = (
    var.rotation_lambda_arn != null &&
    length(var.rotation_lambda_arn) > 0
  )
}


##############################################
# Secrets Manager Secret (container)
##############################################

resource "aws_secretsmanager_secret" "rds_secret" {
  name                           = local.secret_name
  recovery_window_in_days        = 0
  force_overwrite_replica_secret = true
  tags                           = var.tags
}

##############################################
# Secret Value (optional)
#
# If manage_secret_value=false, Terraform will not write/update
# SecretString (useful when importing an existing secret).
##############################################

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  count     = var.manage_secret_value ? 1 : 0
  secret_id = aws_secretsmanager_secret.rds_secret.id

  # JSON structure compatible with common RDS rotation templates
  secret_string = jsonencode({
    username = var.username
    password = var.password
    engine   = "mysql"
    host     = var.address
    port     = var.port
    db_name  = var.dbname
  })
}

##############################################
# Secret Rotation (optional)
#
# Rotation is enabled only when BOTH:
# - rotation_lambda_account_id
# - rotation_lambda_name
# are set.
##############################################

resource "aws_secretsmanager_secret_rotation" "rds_rotation" {
  count = local.rotation_enabled ? 1 : 0

  secret_id           = aws_secretsmanager_secret.rds_secret.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }

  # Ensure SecretString exists before attaching rotation (when managed)
  #depends_on = [aws_secretsmanager_secret_version.rds_secret_version]

  depends_on = [
    aws_secretsmanager_secret_version.rds_secret_version,
    aws_lambda_permission.allow_secretsmanager_invoke_rotation
  ]
}

##############################################
# Lambda Permission for Rotation (optional)
resource "aws_lambda_permission" "allow_secretsmanager_invoke_rotation" {
  count = local.rotation_enabled ? 1 : 0

  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = var.rotation_lambda_arn
  principal     = "secretsmanager.amazonaws.com"

  # Scope permission to THIS secret only
  source_arn = aws_secretsmanager_secret.rds_secret.arn
}
##############################################

