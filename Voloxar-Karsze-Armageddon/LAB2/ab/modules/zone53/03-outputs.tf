#moved to domain_name_init
# output "name_servers" {
#   description = "Name servers for the hosted zone"
#   value       = data.aws_route53_zone.primary.name_servers
# }



output "certificate_arn" {
  description = "Issued ACM certificate ARN"
  value       = aws_acm_certificate_validation.primary_acm_validation.certificate_arn
  depends_on = [ aws_acm_certificate_validation.primary_acm_validation]
}
#the depends on is for the alb

output "Z53zone_id"{
  value = data.aws_route53_zone.primary.zone_id
}