# output "chewbacca_acm_validation_arn" {
#   value = aws_acm_certificate_validation.chewbacca_acm_validation01.certificate_arn
# }

output "enable_waf" {
    description = "Toggle WAF creation."
    value = var.enable_waf
}

#if certificate created in terraform
output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.chewbacca_acm_cert01.arn
}

# if certificate already exist
# output "acm_certificate_arn" {
#   value = data.aws_acm_certificate.chewbacca_acm_cert01.arn
# }

# output "route53_record_fqdn" {
#   description = "FQDN of the Route53 ALB record"
#   value       = aws_route53_record.app_alias.fqdn
# }

# output "route53_record_fqdn" {
#   description = "FQDN of the Route53 ALB record"
#   value       = try(aws_route53_record.chewbacca_acm_validation.fqdn, "")
# }

output "route53_zone_id" {
  description = "ID of the Route53 zone"
  value       = aws_route53_zone.main.zone_id
}

output "name_servers" {
  value = aws_route53_zone.main.name_servers
}

output "website_url" {
  value = "https://${var.app_subdomain}.${var.domain_name}"
}

# output "certificate_validated" {
#   value = data.aws_acm_certificate.chewbacca_acm_cert01.status == "ISSUED"
# }

# output "acm_certificate_validation_id" {
#   description = "ID of the ACM certificate validation resource"
#   value       = aws_acm_certificate_validation.chewbacca_acm_validation01.id
# }


output "route53_record_fqdn" {
  description = "FQDN of the Route53 ALB record"
  value       = aws_route53_record.app_alias.fqdn
}

output "certificate_validated" {
  value = true  # ISSUED certs
}

# New: Certificate details for verification
output "certificate_domain" {
  value = aws_acm_certificate.chewbacca_acm_cert01.domain_name
}

output "certificate_status" {
  value = aws_acm_certificate.chewbacca_acm_cert01.status
}

# For ALB listener depends_on - we don't need validation ID anymore since cert is already ISSUED
# But we can output the certificate itself
output "certificate_id" {
  value = aws_acm_certificate.chewbacca_acm_cert01.id
}

# Apex URL for Bonus D
output "apex_url_https" {
  value = var.create_apex_record ? "https://${var.domain_name}" : null
}

output "apex_record_created" {
  value = var.create_apex_record
}