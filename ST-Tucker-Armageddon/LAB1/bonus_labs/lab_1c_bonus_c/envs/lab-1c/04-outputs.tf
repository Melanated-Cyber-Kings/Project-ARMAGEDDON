###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: environment
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

############################
# Core Outputs
############################
output "vpc_id" {
  value = module.vpc.vpc_id
}

# Keep the output name you already use, but output the correct value.
output "public_subnet_id" {
  value = try(module.vpc.public_subnet_id, try(module.vpc.public_subnet_ids[0], null))
}

# Keep the output name you already use, but output the correct value.
output "private_subnet_id" {
  value = try(module.vpc.private_subnet_id, try(module.vpc.private_subnet_ids[0], null))
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

output "address" {
  value = module.rds.address
}

output "rotation_lambda_name" {
  value = module.lambda_rotation.rotation_lambda_name
}

output "rotation_lambda_account_id" {
  value = module.lambda_rotation.rotation_account_id
}

output "rotation_lambda_arn" {
  description = "Rotation Lambda ARN for Secrets Manager rotation attachment."
  value       = module.lambda_rotation.rotation_lambda_arn
}

# Output for AWS Instance ID
output "ec2_instance_id" {
  description = "Provide ID of running EC2 instance."
  value       = module.ec2.ec2_id
}

output "ec2_public_ip" {
  description = "Provide Public IP of running EC2 instance."
  value       = module.ec2.ec2_public_ip
}

################################################################################
# Bonus C Outputs (Ingress Module)
# IMPORTANT: ingress resources are inside module.ingress — no root aws_* refs here.
################################################################################

# Fully Qualified Domain Name for the Application
output "bonus_c_fqdn" {
  value = "${var.app_subdomain}.${var.domain_name}"
}

# Application Load Balancer DNS Name
output "alb_dns_name" {
  value = module.ingress.alb_dns_name
}

# Application Load Balancer ARN
output "alb_arn" {
  value = module.ingress.alb_arn
}

# Target Group ARN
output "target_group_arn" {
  value = module.ingress.target_group_arn
}

# ACM Certificate ARN
output "acm_certificate_arn" {
  value = module.ingress.acm_certificate_arn
}

# WAF Web ACL ARN
output "waf_web_acl_arn" {
  value = module.ingress.waf_web_acl_arn
}

# CloudWatch Alarm for ALB 5XX Errors
output "alb_5xx_alarm_name" {
  value = try(module.ingress.alb_5xx_alarm_name, null)
}

# CloudWatch Dashboard for the ALB
output "alb_dashboard_name" {
  value = try(module.ingress.alb_dashboard_name, null)
}

# Security Group ID for the ALB
output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = module.security.alb_sg_id
}

# Output the SNS Topic ARN for ALB Notifications
output "sns_topic_arn" {
  value = module.cloudwatch.sns_topic_arn
}

# Output the Route53 Hosted Zone ID used by the Ingress
output "route53_zone_id" {
  description = "Route53 hosted zone id used by ingress (if dns_mode is route53_*)."
  value       = try(module.ingress.route53_zone_id, null)
}


###############################################################################
