###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: secrets (module)
# PURPOSE: Terraform-owned Secrets Manager secret for RDS creds + rotation.
#
# NOTE:
# - This module assumes Terraform owns the secret lifecycle.
# - If the secret already exists, run: terraform destroy (env) then apply.
#
# Workflow for secrets lifecycle management:
# 1. First-time apply (no secret exists)
# Terraform creates the secret container + writes the value + attaches rotation.

# 2. terraform destroy
# Terraform should remove:

# aws_secretsmanager_secret_rotation (detaches rotation)

# aws_lambda_permission

# aws_secretsmanager_secret_version

# aws_secretsmanager_secret (deletes the secret from Secrets Manager)

# 3. Next apply
# No name collision, because the secret was deleted during destroy.
###############################################################################

locals {
  secret_name = "${var.env_prefix}/rds/mysql"

  secret_payload = jsonencode({
    username = var.username
    password = var.password
    engine   = "mysql"
    host     = var.address
    port     = var.port
    dbname   = var.dbname
  })

  rotation_statement_id = "AllowExecutionFromSecretsManager-${replace(local.secret_name, "/", "-")}"
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name                    = local.secret_name
  recovery_window_in_days = 0

  # Could not use force_delete_without_recovery due to issues with terraform version
  # Need to research correct version of Terraform 1.5+ and AWS provider 5.0+ 
  # to use this feature, as it would simplify the lifecycle management of the secret.

  #force_delete_without_recovery  = true
  force_overwrite_replica_secret = true

  tags = merge(
    { Name = local.secret_name },
    var.tags
  )
}

# Always overwrite AWSCURRENT with Terraform’s value (when enabled)
# This ensures the secret value is correct before rotation is enabled.
# Had to add this as a workaround to ensure the secret value is correct before rotation is enabled.
# Encountered issues where terraform cant import if a secret version already exists, 
# and rotation fails if the value is incorrect.


resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  count = var.manage_secret_value ? 1 : 0

  secret_id     = aws_secretsmanager_secret.rds_secret.id
  secret_string = local.secret_payload
}

resource "aws_lambda_permission" "allow_secretsmanager_invoke_rotation" {
  count = var.enable_rotation ? 1 : 0

  statement_id  = local.rotation_statement_id
  action        = "lambda:InvokeFunction"
  function_name = var.rotation_lambda_arn
  principal     = "secretsmanager.amazonaws.com"

  source_arn = aws_secretsmanager_secret.rds_secret.arn
}

resource "aws_secretsmanager_secret_rotation" "rds_rotation" {
  count = var.enable_rotation ? 1 : 0

  secret_id           = aws_secretsmanager_secret.rds_secret.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }

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
