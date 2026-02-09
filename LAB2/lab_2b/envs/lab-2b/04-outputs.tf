###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# LAB:   LAB-2A
# COMPONENT: outputs
# PURPOSE: Root module outputs only (no resources in this file)
###############################################################################

###############################################################################
# Network
###############################################################################

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "public_subnet_id" {
  value       = module.vpc.public_subnet_id
  description = "Public subnet ID (legacy single output)"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "Public subnet IDs"
}

output "private_subnet_id" {
  value       = module.vpc.private_subnet_ids[0]
  description = "Private subnet ID (first private subnet)"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "Private subnet IDs"
}

output "public_route_table_id" {
  value       = module.vpc.public_route_table_id
  description = "Public route table ID"
}

output "private_route_table_id" {
  value       = module.vpc.private_route_table_id
  description = "Private route table ID"
}

###############################################################################
# IAM / EC2
###############################################################################

output "iam_role_name" {
  value       = module.iam.role_name
  description = "IAM role name for EC2"
}

output "iam_instance_profile_name" {
  value       = module.iam.instance_profile_name
  description = "IAM instance profile name for EC2"
}

output "ec2_instance_id" {
  value       = module.ec2.ec2_id
  description = "EC2 instance ID"
}

output "ec2_private_ip" {
  value       = module.ec2.ec2_private_ip
  description = "EC2 private IP"
}

###############################################################################
# RDS
###############################################################################

output "rds_address" {
  value       = module.rds.address
  description = "RDS endpoint address"
}

output "rds_port" {
  value       = module.rds.port
  description = "RDS endpoint port"
}

###############################################################################
# Secrets
###############################################################################

output "rds_secret_id" {
  value       = module.secrets.secret_id
  description = "Secrets Manager secret ID"
}

output "rds_secret_arn" {
  value       = module.secrets.secret_arn
  description = "Secrets Manager secret ARN"
}

output "rds_secret_name" {
  value       = module.secrets.secret_name
  description = "Secrets Manager secret name"
}

###############################################################################
# Rotation
###############################################################################

output "rotation_lambda_name" {
  value       = module.lambda_rotation.rotation_lambda_name
  description = "Rotation Lambda function name"
}

output "rotation_lambda_arn" {
  value       = module.lambda_rotation.rotation_lambda_arn
  description = "Rotation Lambda function ARN"
}

###############################################################################
# Observability / Incident automation
###############################################################################

output "sns_topic_arn" {
  value       = module.cloudwatch.sns_topic_arn
  description = "SNS topic ARN for alarms"
}

output "ssm_parameter_names" {
  value       = module.config_store.ssm_parameter_names
  description = "SSM parameter names written by config-store module"
}

###############################################################################
# LAB-2A Ingress / Edge
###############################################################################

output "alb_dns_name" {
  value       = aws_lb.app_alb.dns_name
  description = "ALB DNS name used as the CloudFront origin"
}

output "alb_https_listener_arn" {
  value       = aws_lb_listener.https_443.arn
  description = "ALB HTTPS listener ARN"
}

output "alb_target_group_arn" {
  value       = aws_lb_target_group.app_tg.arn
  description = "ALB target group ARN"
}

output "edge_cert_arn" {
  value       = aws_acm_certificate.edge_cert.arn
  description = "ACM certificate ARN used by CloudFront/ALB (us-east-1)"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.cf.id
  description = "CloudFront distribution ID"
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.cf.domain_name
  description = "CloudFront distribution domain name"
}

output "cloudfront_waf_arn" {
  value       = aws_wafv2_web_acl.cf_waf.arn
  description = "CloudFront WAF ARN"
}
