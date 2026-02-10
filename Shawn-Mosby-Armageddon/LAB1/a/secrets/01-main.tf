provider "aws" {
  region = var.region
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name                    = "${var.env_prefix}/rds/mysql"
  recovery_window_in_days = 0
  force_overwrite_replica_secret = true
}

# resource "aws_secretsmanager_secret_rotation" "rds_rotation" {
#   secret_id           = aws_secretsmanager_secret.rds_secret.id

#   rotation_rules {
#     automatically_after_days = 30
#   }
# }

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_secret.id

  secret_string = jsonencode({
    username = var.rds_username
    password = var.rds_password
    host = var.address
    port = var.port
    db_name = var.db_name
  })
}

