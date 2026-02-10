# Add to your existing outputs.tf
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.chewbacca_alb01.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.chewbacca_alb01.arn
}

output "target_group_arn" {
  description = "ARN of the Target Group"
  value       = aws_lb_target_group.chewbacca_tg01.arn
}

output "chewbacca_route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = local.chewbacca_zone_id
}

output "chewbacca_app_url_https" {
  description = "HTTPS URL for the application"
  value       = "https://${var.app_subdomain}.${var.domain_name}"
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.chewbacca_acm_cert01.arn
}