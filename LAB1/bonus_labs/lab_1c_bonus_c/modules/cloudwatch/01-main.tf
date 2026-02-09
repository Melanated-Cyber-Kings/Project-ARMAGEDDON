###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: cloudwatch
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

# 1. SNS Topic for Alerts
resource "aws_sns_topic" "db_incidents" {
  name = "lab-db-incidents"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.db_incidents.arn
  protocol  = "email"
  endpoint  = var.email_addresses[0]
}


# 2. CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/lab-rds-app"
  retention_in_days = 7
  tags              = var.tags
}

# 3. Metric Filter (Terraform-managed)
resource "aws_cloudwatch_log_metric_filter" "db_errors" {
  name           = "DBConnectionErrors"
  log_group_name = aws_cloudwatch_log_group.app_logs.name

  # Flask should log this exact token on DB failure
  pattern = "DB_CONNECTION_ERROR"

  metric_transformation {
    name      = "DBConnectionErrors"
    namespace = "Lab/RDSApp"
    value     = "1"
  }
}


# 4. CloudWatch Alarm (driven by the metric filter above)
resource "aws_cloudwatch_metric_alarm" "db_failure" {
  alarm_name          = "lab-db-connection-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DBConnectionErrors"
  namespace           = "Lab/RDSApp"
  period              = 300
  statistic           = "Sum"
  threshold           = 3

  alarm_actions = [aws_sns_topic.db_incidents.arn]
  ok_actions    = [aws_sns_topic.db_incidents.arn]

  treat_missing_data = "notBreaching"

  tags = var.tags
}