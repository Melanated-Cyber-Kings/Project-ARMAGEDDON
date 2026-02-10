output "hosted_zone_name_servers" {
  description = "NS records to be updated at DNS registrar"
  value       = aws_route53_zone.this.name_servers
}

output "hosted_zone_id" {
  value = aws_route53_zone.this.zone_id
}