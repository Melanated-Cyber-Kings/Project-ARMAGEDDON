output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  value = module.vpc.private_subnet_id
}

output "public_route_table_id" {
  value = module.vpc.public_route_table_id
}

output "private_route_table_id" {
  value = module.vpc.private_route_table_id
}

output "iam_role_name" {
  value = module.iam.role_name
}

output "iam_instance_profile_name" {
  value = module.iam.instance_profile_name
}

# --- OBSERVABILITY OUTPUTS ---

output "sns_topic_arn" {
  description = "The ARN of the SNS Alert Topic"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "The Name of the SNS Alert Topic"
  value       = aws_sns_topic.alerts.name
}

output "cw_alarm_arn" {
  description = "The ARN of the CloudWatch Alarm"
  value       = module.observability.alarm_arn
}