###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: cloudwatch
# PURPOSE: Outputs for consuming stacks (envs)
###############################################################################

output "sns_topic_arn" {
  description = "ARN of the SNS topic used for incident alerts"
  value       = aws_sns_topic.db_incidents.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group used for app logs"
  value       = aws_cloudwatch_log_group.app_logs.name
}

output "alarm_name" {
  description = "Name of the CloudWatch alarm created by this module"
  value       = aws_cloudwatch_metric_alarm.db_failure.alarm_name
}
