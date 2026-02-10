###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: secrets (module)
# PURPOSE: Create/update Secrets Manager secret for DB credentials and (optionally)
#          configure rotation.
###############################################################################

locals {
  secret_name = "${var.env_prefix}/rds/mysql"
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name        = local.secret_name
  description = "RDS credentials for ${var.env_prefix}"

  recovery_window_in_days        = 0
  force_overwrite_replica_secret = true

  tags = merge(var.tags, {
    Name   = "${var.env_prefix}-rds-secret"
    Module = "secrets"
  })
}

resource "aws_secretsmanager_secret_version" "rds_secret_value" {
  count     = var.manage_secret_value ? 1 : 0
  secret_id = aws_secretsmanager_secret.rds_secret.id

  secret_string = jsonencode({
    username = var.username
    password = var.password
    host     = var.address
    port     = var.port
    dbname   = var.dbname
  })
}

resource "aws_secretsmanager_secret_rotation" "rotation" {
  count = var.enable_rotation ? 1 : 0

  secret_id           = aws_secretsmanager_secret.rds_secret.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }

  lifecycle {
    precondition {
      condition     = !var.enable_rotation || (var.rotation_lambda_arn != null && length(var.rotation_lambda_arn) > 0)
      error_message = "enable_rotation=true requires rotation_lambda_arn to be set."
    }
  }

  depends_on = [aws_secretsmanager_secret_version.rds_secret_value]
}
