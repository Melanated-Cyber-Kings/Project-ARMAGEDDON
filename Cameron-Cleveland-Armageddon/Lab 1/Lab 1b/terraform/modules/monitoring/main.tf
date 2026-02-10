# CloudWatch Log Group for Application
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/lab1b-app"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.logs.arn

  tags = {
    Name        = "${var.project_name}-app-logs"
    Project     = var.project_name
    Environment = var.environment
  }
}

# SNS Topic for Alarms (created here to avoid circular dependency)
resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-monitoring-alarms"

  tags = {
    Name        = "${var.project_name}-monitoring-alarms"
    Project     = var.project_name
    Environment = var.environment
  }
}

# CloudWatch Metric Filter for DB Connection Failures
resource "aws_cloudwatch_log_metric_filter" "db_connection_failure" {
  name           = "${var.project_name}-db-connection-failure"
  pattern        = "DB_CONNECTION_FAILURE"
  log_group_name = aws_cloudwatch_log_group.app.name

  metric_transformation {
    name          = "DBConnectionFailureCount"
    namespace     = "Lab1b"
    value         = "1"
    default_value = "0"
  }
}

# KMS Key for CloudWatch Logs encryption
resource "aws_kms_key" "logs" {
  description             = "KMS key for CloudWatch Logs encryption - redeploy"
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
          Service = "logs.ap-northeast-1.amazonaws.com"
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
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:ap-northeast-1:${var.account_id}:log-group:/aws/ec2/lab1b-app"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-logs-kms-redeploy"
    Project     = var.project_name
    Environment = var.environment
  }
}


# CloudWatch Alarm for DB Connection Failures
resource "aws_cloudwatch_metric_alarm" "db_connection_failure" {
  alarm_name          = "${var.project_name}-db-connection-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DBConnectionFailureCount"
  namespace           = "Lab1b"
  period              = "60"
  statistic           = "Sum"
  threshold           = "3"
  alarm_description   = "Triggers when database connection failures exceed threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LogGroupName = aws_cloudwatch_log_group.app.name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = {
    Name        = "${var.project_name}-db-connection-failure-alarm"
    Project     = var.project_name
    Environment = var.environment
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["Lab1b", "DBConnectionFailureCount", { "stat" : "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "Database Connection Failures"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_instance_id]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "RDS Database Connections"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.ec2_instance_id]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "EC2 CPU Utilization"
        }
      }
    ]
  })
}
resource "aws_kms_alias" "logs" {
  name          = "alias/${var.project_name}-logs-kms-redeploy"
  target_key_id = aws_kms_key.logs.key_id
}
