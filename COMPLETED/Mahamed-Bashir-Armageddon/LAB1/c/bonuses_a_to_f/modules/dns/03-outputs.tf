output "certificate_arn" {
  description = "The ARN of the validated certificate"
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "hosted_zone_name_servers" {
  description = "NS records to be updated at your registrar"
  value       = aws_route53_zone.this.name_servers
}