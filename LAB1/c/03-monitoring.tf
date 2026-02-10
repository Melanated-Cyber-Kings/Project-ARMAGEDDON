# ############################################
# # CloudWatch Logs (Log Group)
# ############################################ 

# Explanation: When the Falcon is on fire, logs tell you *which* wire sparked—ship them centrally.
resource "aws_cloudwatch_log_group" "log_group01" {
  name              = "/aws/ec2/${local.name_prefix}-rds-app"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-log-group01"
  }
}

############################################
# 2. Metric Filter (The "Bridge")
############################################
# This scans logs for "ERROR" and increments a counter.
resource "aws_cloudwatch_log_metric_filter" "db_error_filter" {
  name           = "DBConnectionErrorFilter"
  pattern        = "DB_CONNECT_FAIL" # Looks for the literal string ERROR
  log_group_name = aws_cloudwatch_log_group.log_group01.name
  # log_group_name = "/aws/ec2/armageddon-class7-rds-app"
  metric_transformation {
    name      = "DBConnectionErrors" # Must match the Alarm metric_name below
    namespace = "Lab/RDSApp"         # Must match the Alarm namespace below
    value     = "1"                  # Increment the count by 1 for every match
  }
}

# ############################################
# # Custom Metric + Alarm (Skeleton)
# ############################################
 
# This aws_cloudwatch_log_metric_filter creates the DBConnectionErrors metric in the Lab/RDSApp 
# namespace dynamically as your EC2 sends logs.

# Low Threshold: I set the threshold to 1 and the period to 60. This ensures that as soon as you 
# simulate a failure (Step 7.5), the alarm triggers quickly so you don't have to wait 5 minutes for your "Incident Response Proof."

# Important Reminder for EC2:
# For this alarm to trigger, your application on the EC2 must write to the log file that the CloudWatch Agent is shipping. 
# If your app doesn't print the word ERROR to the log, the filter will never see it, and the alarm will stay OK.
############################################
# 3. CloudWatch Alarm (The "Siren")
############################################
# Explanation: Metrics are Chewbacca’s growls—when they spike, something is wrong.
# NOTE: Students must emit the metric from app/agent; this just declares the alarm.
resource "aws_cloudwatch_metric_alarm" "db_alarm01" {
  alarm_name          = "${local.name_prefix}-db-connection-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DBConnectionErrors"
  namespace           = "Lab/RDSApp"
  period              = "60" # Check every minute for faster lab verification
  statistic           = "Sum"
  threshold           = "1" # Trigger alarm on the very first error

  alarm_actions       = [aws_sns_topic.sns_topic01.arn]

  # Ensures the alarm resets when errors stop
  treat_missing_data  = "notBreaching"

  tags = {
    Name = "${local.name_prefix}-alarm-db-fail"
  }
}









# # ############################################
# # # Custom Metric + Alarm (Skeleton)
# # ############################################

# # Explanation: Metrics are Chewbacca’s growls—when they spike, something is wrong.
# # NOTE: Students must emit the metric from app/agent; this just declares the alarm.
# resource "aws_cloudwatch_metric_alarm" "db_alarm01" {
#   alarm_name          = "${local.name_prefix}-db-connection-failure"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = 1
#   metric_name         = "DBConnectionErrors"
#   namespace           = "Lab/RDSApp"
#   period              = 300
#   statistic           = "Sum"
#   threshold           = 3

#   alarm_actions       = [aws_sns_topic.sns_topic01.arn]

#   tags = {
#     Name = "${local.name_prefix}-alarm-db-fail"
#   }
# }





