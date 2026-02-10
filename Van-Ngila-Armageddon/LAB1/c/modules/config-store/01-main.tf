# SSM Parameters for DB configuration
resource "aws_ssm_parameter" "db_endpoint" {
  name        = "/lab/db/endpoint"
  type        = "String"
  value       = var.db_endpoint
  description = "RDS endpoint for lab application"
  tags        = var.tags
}

resource "aws_ssm_parameter" "db_port" {
  name        = "/lab/db/port"
  type        = "String"
  value       = var.db_port
  description = "RDS port for lab application"
  tags        = var.tags
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/lab/db/name"
  type        = "String"
  value       = var.db_name
  description = "RDS database name for lab application"
  tags        = var.tags
}

# Secrets Manager for DB credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "lab/rds/mysql"
  description = "Database credentials for lab RDS instance"

  recovery_window_in_days = 0
  force_overwrite_replica_secret = true
  
  tags = merge(var.tags, {
    Rotation = "manual"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_endpoint
    port     = var.db_port
    dbname   = var.db_name
  })
}
