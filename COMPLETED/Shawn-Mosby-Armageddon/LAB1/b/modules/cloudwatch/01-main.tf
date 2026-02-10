# Create the Log Group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/lab-rds-app"
  retention_in_days = 7
}

# Create a Metric Filter (Looks for the word "ERROR" in logs)
resource "aws_cloudwatch_log_metric_filter" "db_error_filter" {
  name           = "DatabaseConnectionErrors"
  pattern        = "ERROR" # This matches what your Python app will log
  log_group_name = aws_cloudwatch_log_group.app_logs.name

  metric_transformation {
    name      = "DBErrorCount"
    namespace = "Lab/RDSApp"
    value     = "1"
  }
}

# Create the Alarm
resource "aws_cloudwatch_metric_alarm" "db_connection_failure" {
  alarm_name          = "lab-db-connection-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DBErrorCount"
  namespace           = "Lab/RDSApp"
  period              = "300"
  statistic           = "Sum"
  threshold           = "3"
  alarm_description   = "This alarm fires if the app logs a DB connection error."
  alarm_actions       = [aws_sns_topic.db_incidents.arn]
  ok_actions          = [aws_sns_topic.db_incidents.arn]
  
  dimensions = {
    LogGroupName = aws_cloudwatch_log_group.app_logs.name
  }
  
  tags = var.tags # You can add SNS topics or other actions here
}

resource "aws_sns_topic" "db_incidents" {
  name = "lab-db-incidents"
}

resource "aws_sns_topic_subscription" "email" {
  endpoint = "shawnmosby225@gmail.com"
  topic_arn = aws_sns_topic.db_incidents.arn
  protocol = "email"
}