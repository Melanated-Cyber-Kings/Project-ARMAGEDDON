output "name_servers" {
  description = "Name servers for the hosted zone"
  value       = aws_route53_zone.primary.name_servers
}