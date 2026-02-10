# output "chewbacca_acm_validation_arn" {
#   value = aws_acm_certificate_validation.chewbacca_acm_validation01.certificate_arn
# }

output "enable_waf" {
    description = "Toggle WAF creation."
    value = var.enable_waf
}

#if certificate created in terraform
# output "acm_certificate_arn" {
#   description = "ARN of the ACM certificate"
#   value       = aws_acm_certificate.chewbacca_acm_cert01.arn
# }

# if certificate already exist
output "acm_certificate_arn" {
  value = data.aws_acm_certificate.chewbacca_acm_cert01.arn
}

output "route53_record_fqdn" {
  description = "FQDN of the Route53 ALB record"
  value       = aws_route53_record.chewbacca_acm_validation.fqdn
}

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

output "certificate_validated" {
  value = data.aws_acm_certificate.chewbacca_acm_cert01.status == "ISSUED"
}