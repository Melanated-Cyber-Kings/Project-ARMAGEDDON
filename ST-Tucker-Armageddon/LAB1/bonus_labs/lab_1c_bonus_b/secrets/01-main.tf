###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: secrets
# PURPOSE: Create Secrets Manager secret for RDS creds, and optionally configure
#          rotation via Lambda.
###############################################################################

##############################################
# Locals
##############################################

locals {
  # Secret name convention used in this lab
  secret_name = "${var.env_prefix}/rds/mysql"

  # Rotation enabled only when explicitly enabled AND an ARN is provided
  rotation_enabled = (
    var.enable_rotation == true &&
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

  tags = merge(
    {
      Name = local.secret_name
    },
    var.tags
  )
}

##############################################
# Secret Value (SecretString)
##############################################

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  count = var.manage_secret_value ? 1 : 0

  secret_id = aws_secretsmanager_secret.rds_secret.id

  secret_string = jsonencode({
    username = var.username
    password = var.password
    engine   = "mysql"
    host     = var.address
    port     = var.port
    dbname   = var.dbname
  })
}

##############################################
# Lambda Permission (only when rotation enabled)
##############################################

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
# Secret Rotation (optional)
##############################################

resource "aws_secretsmanager_secret_rotation" "rds_rotation" {
  count = local.rotation_enabled ? 1 : 0

  secret_id           = aws_secretsmanager_secret.rds_secret.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }

  # Ensure SecretString exists before attaching rotation (when managed)
  depends_on = [
    aws_secretsmanager_secret_version.rds_secret_version,
    aws_lambda_permission.allow_secretsmanager_invoke_rotation
  ]

  lifecycle {
    precondition {
      condition     = !var.enable_rotation || (var.rotation_lambda_arn != null && length(var.rotation_lambda_arn) > 0)
      error_message = "enable_rotation=true requires rotation_lambda_arn to be set."
    }
  }
}
