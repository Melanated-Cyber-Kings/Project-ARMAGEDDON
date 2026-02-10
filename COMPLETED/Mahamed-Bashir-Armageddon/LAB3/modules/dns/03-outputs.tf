output "hosted_zone_name_servers" {
  description = "NS records to be updated at your registrar"
  value       = aws_route53_zone.this.name_servers
}

output "hosted_zone_id" {
  value = aws_route53_zone.this.zone_id
}

output "validation_record_fqdns" {
  description = "List of FQDNs for ACM validation"
  # We use a splat/loop to get all fqdns from the map
  value       = [for record in aws_route53_record.validation : record.fqdn]
}