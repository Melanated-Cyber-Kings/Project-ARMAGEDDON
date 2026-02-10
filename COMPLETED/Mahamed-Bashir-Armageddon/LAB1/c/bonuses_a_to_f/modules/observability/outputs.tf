output "log_group_arn" {
  value = aws_cloudwatch_log_group.this.arn
}

output "alarm_arn" {
  value = aws_cloudwatch_metric_alarm.this.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.this.name
}

