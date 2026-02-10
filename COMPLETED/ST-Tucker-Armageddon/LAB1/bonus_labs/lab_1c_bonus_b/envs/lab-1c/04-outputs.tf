###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: environment
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  value = module.vpc.private_subnet_ids
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

# output "port" {
#   value = module.rds.port
# }

# Output for Relational Database Service (RDS) Address
# Used for EC2 to connect to RDS instance

# Used in user_data of EC2 module
# Used in application configuration
# Used in Secrets Manager rotation attachment

# Used in Security Group ingress rule for EC2 to RDS access
output "RDS_address" {
  value = module.rds.address
}

# Output for Rotation Lambda Name
# Used for Secrets Manager rotation attachment
# (typically the same account as this infrastructure)

output "rotation_lambda_name" {
  value = module.lambda_rotation.rotation_lambda_name
}

# Output for Rotation Lambda Account ID
# Used for Secrets Manager rotation attachment
# (typically the same account as this infrastructure)

output "rotation_lambda_account_id" {
  value = module.lambda_rotation.rotation_account_id
}

# Output for Rotation Lambda ARN
# Used for Secrets Manager rotation attachment
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

###############################################################################
# Bonus C Outputs
###############################################################################

# Fully Qualified Domain Name for the Application
output "bonus_b_fqdn" {
  value = "${var.app_subdomain}.${var.domain_name}"
}

# Application Load Balancer DNS Name
output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

#  Application Load Balancer ARN
output "alb_arn" {
  value = aws_lb.app_alb.arn
}

#  Target Group ARN
output "target_group_arn" {
  value = aws_lb_target_group.app_tg.arn
}

#  ACM Certificate ARN
output "acm_certificate_arn" {
  value = aws_acm_certificate.app_cert.arn
}

#   WAF Web ACL ARN
output "waf_web_acl_arn" {
  value = aws_wafv2_web_acl.alb_waf.arn
}

# CloudWatch Alarm for ALB 5XX Errors
output "alb_5xx_alarm_name" {
  value = aws_cloudwatch_metric_alarm.alb_5xx.alarm_name
}

# CloudWatch Dashboard for the ALB
output "alb_dashboard_name" {
  value = aws_cloudwatch_dashboard.alb_dashboard.dashboard_name
}

# Security Group ID for the ALB
output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = module.security.alb_sg_id

}


#Outout SNS topic ARN for ALB 5XX Alarm Notifications
output "sns_topic_arn" {
  description = "ARN of the SNS topic for ALB 5XX alarm notifications"
  value       = module.cloudwatch.sns_topic_arn
}

###############################################################################