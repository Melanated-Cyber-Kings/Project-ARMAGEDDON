provider "aws" {
  region = var.region
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name                           = "${var.env_prefix}/rds/mysql"
  recovery_window_in_days        = 0
  force_overwrite_replica_secret = true
}

# resource "aws_secretsmanager_secret_rotation" "rds_rotation" {
#   secret_id           = aws_secretsmanager_secret.rds_secret.id
#   rotation_lambda_arn = "arn:aws:lambda:ap-northeast-1:619076214091:function:rotation"
#   rotation_rules {
#     automatically_after_days = 30
#   }
# }

# resource "aws_lambda_permission" "allow_secrets_manager" {
#   statement_id  = "AllowExecutionFromSecretsManager"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_secretsmanager_secret_rotation.rds_rotation 
#   principal     = "secretsmanager.amazonaws.com"
# }

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_secret.id

  secret_string = jsonencode({
    username = var.username
    password = var.password
    host     = var.address
    port     = var.port
    db_name  = var.dbname
  })
}

