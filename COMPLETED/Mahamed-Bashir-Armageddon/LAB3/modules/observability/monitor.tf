# # monitoring.tf
# # Add these to your existing Terraform setup

# # 1. SNS Topic for Alerts
# resource "aws_sns_topic" "db_incidents" {
#   name = "lab-db-incidents"
# }

# resource "aws_sns_topic_subscription" "email" {
#   topic_arn = aws_sns_topic.db_incidents.arn
#   protocol  = "email"
#   endpoint  = "YOUR_EMAIL@example.com"  # ⚠️ CHANGE THIS
# }

# # 2. CloudWatch Log Group (if not already exists)
# resource "aws_cloudwatch_log_group" "app_logs" {
#   name = "/aws/ec2/lab-rds-app"
#   retention_in_days = 7
# }

# # 3. CloudWatch Alarm (simplified - we'll create metric filter via CLI later)
# resource "aws_cloudwatch_metric_alarm" "db_failure" {
#   alarm_name          = "lab-db-connection-failure"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "DBConnectionErrors"
#   namespace           = "Lab/RDSApp"
#   period              = "300"
#   statistic           = "Sum"
#   threshold           = "3"
#   alarm_actions       = [aws_sns_topic.db_incidents.arn]
#   ok_actions          = [aws_sns_topic.db_incidents.arn]
  
#   # We'll add dimensions after creating the metric filter
#   dimensions = {}
# }