############################################
# Bonus-B: DNS, TLS & Observability Outputs
############################################

output "route53_nameservers" {
  description = "The nameservers for your Hosted Zone. Update your registrar with these if creating a new zone."
  value       = try(aws_route53_zone.main[0].name_servers, "Using existing zone")
}

output "app_https_url" {
  description = "The final secure URL for your application."
  value       = "https://${var.app_subdomain}.${var.domain_name}"
}

output "certificate_status" {
  description = "The status of the ACM certificate validation."
  value       = aws_acm_certificate.cert.status
}

output "cloudwatch_dashboard_url" {
  description = "Direct link to your dashboard in the AWS Console."
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}-enterprise-dashboard"
}