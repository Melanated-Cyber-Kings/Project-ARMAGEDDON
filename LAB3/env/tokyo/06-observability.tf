# ==============================================================================
# OBSERVABILITY LAYER
# Handles Alerts, Metrics, and Logging Configuration
# ==============================================================================

# 1. SNS Topic
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
}

# 2. Subscriber
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.sns_email
}

# 3. Watcher 
module "observability" {
  source = "../../modules/observability"

  name_prefix      = local.name_prefix
  log_group_name   = "/aws/ec2/lab-rds-app"
  
  # Failure Pattern to Monitor
  filter_pattern   = "CRITICAL"
  
  metric_name      = "DBConnectionErrors"
  metric_namespace = "Lab/RDSApp"
  threshold        = 3
  
  # Connect the Alarm to the Topic
  alarm_actions    = [aws_sns_topic.alerts.arn]
}