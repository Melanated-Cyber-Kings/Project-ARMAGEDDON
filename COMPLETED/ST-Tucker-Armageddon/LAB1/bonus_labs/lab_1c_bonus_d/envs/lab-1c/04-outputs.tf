###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: environment
# FILE: 04-outputs.tf
# PURPOSE:  Outputs for Lab-1C (core + bonuses)
###############################################################################

############################################
# Core Networking
############################################
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = try(module.vpc.public_subnet_id, try(module.vpc.public_subnet_ids[0], null))
}

output "private_subnet_id" {
  value = try(module.vpc.private_subnet_id, try(module.vpc.private_subnet_ids[0], null))
}

output "public_route_table_id" {
  value = module.vpc.public_route_table_id
}

output "private_route_table_id" {
  value = module.vpc.private_route_table_id
}

############################################
# Core Compute + IAM
############################################
output "iam_role_name" {
  value = module.iam.role_name
}

output "iam_instance_profile_name" {
  value = module.iam.instance_profile_name
}

output "ec2_instance_id" {
  description = "Running EC2 instance ID."
  value       = module.ec2.ec2_id
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance (if assigned)."
  value       = module.ec2.ec2_public_ip
}

############################################
# Core Data + Rotation
############################################
output "rds_address" {
  description = "RDS endpoint address."
  value       = module.rds.address
}

output "rotation_lambda_name" {
  value = module.lambda_rotation.rotation_lambda_name
}

output "rotation_lambda_arn" {
  description = "Rotation Lambda ARN for Secrets Manager rotation attachment."
  value       = module.lambda_rotation.rotation_lambda_arn
}

############################################
# Observability + Notifications
############################################
output "sns_topic_arn" {
  value = module.cloudwatch.sns_topic_arn
}

############################################
# Ingress (Bonus B/C/D) — ALB + Route53 + ACM + WAF + Logging
# IMPORTANT: These are the outputs your validation scripts should consume.
############################################

# Domains
output "apex_fqdn" {
  description = "Apex domain (e.g., devlab405.click)."
  value       = var.domain_name
}

output "app_fqdn" {
  description = "App FQDN (e.g., app.devlab405.click)."
  value       = "${var.app_subdomain}.${var.domain_name}"
}

output "apex_url_https" {
  description = "HTTPS URL for apex routed to the ALB."
  value       = "https://${var.domain_name}"
}

output "domain_name" {
  description = "Compatibility output: apex domain name."
  value       = var.domain_name
}


output "app_url_https" {
  description = "HTTPS URL for the app subdomain routed to the ALB."
  value       = "https://${var.app_subdomain}.${var.domain_name}"
}

# ALB
output "alb_dns_name" {
  value = module.ingress.alb_dns_name
}

output "alb_arn" {
  value = module.ingress.alb_arn
}

output "target_group_arn" {
  value = module.ingress.target_group_arn
}

# ACM + WAF
output "acm_certificate_arn" {
  value = module.ingress.acm_certificate_arn
}

output "waf_web_acl_arn" {
  value = module.ingress.waf_web_acl_arn
}

# Ingress alarms/dashboards (optional / may be null)
output "alb_5xx_alarm_name" {
  value = try(module.ingress.alb_5xx_alarm_name, null)
}

output "alb_dashboard_name" {
  value = try(module.ingress.alb_dashboard_name, null)
}

# Route53 zone used by ingress (null in external DNS mode)
output "route53_zone_id" {
  description = "Route53 hosted zone id used by ingress (dns_mode route53_*)."
  value       = try(module.ingress.route53_zone_id, null)
}

# ALB Access Logging (Bonus D)
output "alb_logs_bucket_name" {
  description = "S3 bucket receiving ALB access logs (if enabled)."
  value       = try(module.ingress.alb_logs_bucket_name, null)
}

output "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs."
  value       = try(module.ingress.alb_access_logs_prefix, null)
}

############################################
# Security Group outputs (Bonus A)
############################################
output "alb_sg_id" {
  description = "ALB security group ID."
  value       = module.security.alb_sg_id
}
