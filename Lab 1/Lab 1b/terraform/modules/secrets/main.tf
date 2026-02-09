# KMS Key for Secrets Encryption
resource "aws_kms_key" "secrets" {
  description             = "KMS key for secrets and logs encryption - redeploy19"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/ec2/${var.project_name}-*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-secrets-kms-redeploy19"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project_name}-secrets-redeploy19"
  target_key_id = aws_kms_key.secrets.key_id
}

# SSM Parameter Store - Database Configuration
resource "aws_ssm_parameter" "db_endpoint" {
  name        = "/lab1b/db/endpoint"
  description = "RDS MySQL endpoint"
  type        = "String"
  value       = var.db_endpoint

  tags = {
    Name        = "${var.project_name}-db-endpoint"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "db_port" {
  name        = "/lab1b/db/port"
  description = "RDS MySQL port"
  type        = "String"
  value       = var.db_port

  tags = {
    Name        = "${var.project_name}-db-port"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/lab1b/db/name"
  description = "RDS MySQL database name"
  type        = "String"
  value       = var.db_name

  tags = {
    Name        = "${var.project_name}-db-name"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Secrets Manager - Database Credentials
resource "aws_secretsmanager_secret" "rds_mysql" {
  name        = "lab1b/rds/mysql-19"
  description = "RDS MySQL database credentials"
  kms_key_id  = aws_kms_key.secrets.key_id

  tags = {
    Name        = "${var.project_name}-rds-mysql-secret19"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "rds_mysql" {
  secret_id = aws_secretsmanager_secret.rds_mysql.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_endpoint
    port     = var.db_port
    database = var.db_name
    engine   = "mysql"
  })
}

# IAM Policy for Secret Access (for other services)
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.project_name}-secrets-access-policy"
  description = "Policy to access SSM and Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:ssm:${var.region}:${var.account_id}:parameter/lab1b/*"
        ]
      },
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect = "Allow"
        Resource = [
          aws_secretsmanager_secret.rds_mysql.arn
        ]
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Effect = "Allow"
        Resource = [
          aws_kms_key.secrets.arn
        ]
      }
    ]
  })
}