output "log_group_name" {
  value = aws_cloudwatch_log_group.app.name
}

output "alarm_arn" {
  value = aws_cloudwatch_metric_alarm.db_connection_failure.arn
}

output "alarm_name" {
  value = aws_cloudwatch_metric_alarm.db_connection_failure.alarm_name
}

output "sns_topic_arn" {
  value = aws_sns_topic.alarms.arn
}