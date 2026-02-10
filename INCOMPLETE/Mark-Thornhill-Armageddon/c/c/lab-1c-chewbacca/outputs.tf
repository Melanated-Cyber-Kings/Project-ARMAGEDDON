############################################
# VPC & Networking Outputs
############################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.chewbacca_vpc01.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.chewbacca_public_subnets[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.chewbacca_private_subnets[*].id
}

output "chewbacca_apex_url_https" {
  value = var.is_lab_active ? "https://${var.domain_name}" : null
}

############################################
# Compute, Load Balancer & RDS Outputs
############################################

output "chewbacca_ec2_instance_id" {
  description = "The ID of the Private EC2 instance"
  value       = aws_instance.chewbacca_ec201.id
}

output "alb_dns_name" {
  description = "The DNS name of the Load Balancer"
  value       = aws_lb.chewbacca_alb01[0].dns_name
}

output "chewbacca_rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.chewbacca_rds01.address
}

############################################
# Secrets & SSM Outputs
############################################

output "db_secret_arn" {
  description = "The ARN of the secret in Secrets Manager"
  value       = aws_secretsmanager_secret.chewbacca_db_secret01.arn
}

output "db_endpoint_ssm_path" {
  description = "The SSM Parameter path for the DB endpoint"
  value       = aws_ssm_parameter.chewbacca_db_endpoint_param.name
}

############################################
# Notifications
############################################

output "sns_topic_arn" {
  description = "The ARN of the SNS topic for alerts"
  value       = aws_sns_topic.chewbacca_sns_topic01.arn
}

############################################
# Logs
############################################
output "chewbacca_alb_logs_bucket_name" {
  value = (var.enable_alb_access_logs && var.is_lab_active) ? aws_s3_bucket.chewbacca_alb_logs_bucket01[0].bucket : null
}

############################################
# Lab 1d_bonus-E
############################################
output "chewbacca_waf_log_destination" {
  value = var.waf_log_destination
}

output "chewbacca_waf_cw_log_group_name" {
  value = var.waf_log_destination == "cloudwatch" ? aws_cloudwatch_log_group.chewbacca_waf_log_group01[0].name : null
}

output "chewbacca_waf_logs_s3_bucket" {
  value = var.waf_log_destination == "s3" ? aws_s3_bucket.chewbacca_waf_logs_bucket01[0].bucket : null
}

output "chewbacca_waf_firehose_name" {
  value = var.waf_log_destination == "firehose" ? aws_kinesis_firehose_delivery_stream.chewbacca_waf_firehose01[0].name : null
}