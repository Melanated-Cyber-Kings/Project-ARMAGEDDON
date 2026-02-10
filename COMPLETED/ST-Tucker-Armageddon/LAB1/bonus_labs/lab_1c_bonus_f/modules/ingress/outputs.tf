###############################################################################
# outputs.tf
# Module: ingress (Lab-1C )
###############################################################################

############################################
# Domain convenience
############################################

# Apex HTTPS URL (handy for validation & lab instructions)
output "apex_url_https" {
  description = "HTTPS URL for the apex domain routed to the ALB."
  value       = "https://${var.domain_name}"
}

# App HTTPS URL (handy for validation)
output "app_url_https" {
  description = "HTTPS URL for the app subdomain routed to the ALB."
  value       = "https://${var.app_subdomain}.${var.domain_name}"
}

############################################
# ALB
############################################

output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "alb_arn" {
  value = aws_lb.app_alb.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.app_tg.arn
}

############################################
# ACM
############################################

# The ACM certificate ARN is useful for reference and for any future manual associations 
# with other resources (e.g. API Gateway).
# In a real-world scenario, you might have multiple certificates for different domains 
# or subdomains, so having the ARN as an output can be helpful for reference and management purposes.
# Additionally, if you need to perform any manual operations with the certificate 
# (e.g. revalidation, deletion), having the ARN readily available can save time and reduce the risk of errors.
#
# Reference: AWS ACM certificate ARN: https://docs.aws.amazon.com/acm/latest/userguide/acm-overview.html#acm-arn

output "acm_certificate_arn" {
  value = aws_acm_certificate.app_cert.arn
}

############################################
# WAF
############################################

# The WAF ARN is needed to associate it with the ALB, but it's also useful to have it as an output 
# for any future manual associations with other resources (e.g. API Gateway).
# In a real-world scenario, you might have multiple WAFs for different resources, so having the 
# ARN as an output can be helpful for reference and management purposes.
#
# Reference: AWS WAF ARN: https://docs.aws.amazon.com/waf/latest/developerguide/web-acl-arn.html

output "waf_web_acl_arn" {
  value = aws_wafv2_web_acl.alb_waf.arn
}

############################################
# Observability
############################################

# The ALB 5xx alarm provides the name of the CloudWatch alarm that monitors 5xx errors for the ALB.
# Reference: 5xx errors alarm: https://aws.amazon.com/blogs/mt/monitoring-application-load-balancers-with-amazon-cloudwatch-dashboards/

output "alb_5xx_alarm_name" {
  value = aws_cloudwatch_metric_alarm.alb_5xx.alarm_name
}

# The ALB dashboard provides the name of the CloudWatch dashboard that visualizes ALB metrics.
# Reference: 5xx errors dashboard: https://aws.amazon.com/blogs/mt/monitoring-application-load-balancers-with-amazon-cloudwatch-dashboards/

output "alb_dashboard_name" {
  value = aws_cloudwatch_dashboard.alb_dashboard.dashboard_name
}

############################################
# ALB Access Logging 
############################################

# The ALB access logs bucket name is useful for reference and for any future manual access to the logs.
# Reference: ALB access logs bucket name: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-log-bucket-name

output "alb_logs_bucket_name" {
  value = var.enable_alb_access_logs ? aws_s3_bucket.alb_logs[0].bucket : null
}

# Prefix is useful for validation scripts and troubleshooting.
output "alb_access_logs_prefix" {
  description = "S3 prefix used for ALB access logs."
  value       = var.alb_access_logs_prefix
}

############################################
# Route53 / DNS
############################################

# The Route 53 zone ID is needed for creating DNS records that point to the ALB.
# It is also useful for scripting and automation purposes, as it allows you to 
# programmatically manage DNS records in the correct hosted zone.
#
# Reference: AWS Route 53 hosted zone ID: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-working-with.html#hosted-zones-getting-hosted-zone-id

output "route53_zone_id" {
  value = try(local.zone_id, null)
}

# For external DNS mode: output what ACM expects so the user can create records manually.
# Reference: https://www.terraform.io/language/values/outputs#best-practices-for-outputs
# Reference: https://www.terraform.io/language/values/outputs#sensitive-outputs
# Reference ACM DNS validation: https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-dns.html

output "acm_dns_validation_records" {
  value = [
    for dvo in tolist(aws_acm_certificate.app_cert.domain_validation_options) : {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  ]
}

############################################
# WAF Logging 
############################################

# Reference: AWS WAF logging destinations: https://docs.aws.amazon.com/waf/latest/developerguide/logging.html#logging-destinations

output "waf_log_destination" {
  description = "Selected WAF log destination (cloudwatch|s3|firehose)."
  value       = var.waf_log_destination
}

output "waf_cw_log_group_name" {
  description = "CloudWatch log group for WAF logs (if cloudwatch selected)."
  value       = var.waf_log_destination == "cloudwatch" ? aws_cloudwatch_log_group.waf_logs[0].name : null
}

# Use for S3/Firehose reference and validation.

output "waf_logs_s3_bucket" {
  value = var.waf_log_destination == "s3" ? aws_s3_bucket.waf_logs[0].bucket : null
}

output "waf_firehose_name" {
  value = var.waf_log_destination == "firehose" ? aws_kinesis_firehose_delivery_stream.waf_logs[0].name : null
}

output "waf_firehose_dest_bucket" {
  value = var.waf_log_destination == "firehose" ? aws_s3_bucket.waf_firehose_dest[0].bucket : null
}
