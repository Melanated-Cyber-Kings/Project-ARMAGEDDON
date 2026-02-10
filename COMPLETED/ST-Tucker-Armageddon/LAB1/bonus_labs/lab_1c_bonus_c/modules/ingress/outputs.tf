###############################################################################
# outputs.tf
# Module: ingress (Lab-1C Bonus C)
###############################################################################

output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "alb_arn" {
  value = aws_lb.app_alb.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.app_tg.arn
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.app_cert.arn
}

output "waf_web_acl_arn" {
  value = aws_wafv2_web_acl.alb_waf.arn
}

output "alb_5xx_alarm_name" {
  value = aws_cloudwatch_metric_alarm.alb_5xx.alarm_name
}

output "alb_dashboard_name" {
  value = aws_cloudwatch_dashboard.alb_dashboard.dashboard_name
}

output "route53_zone_id" {
  value = try(local.zone_id, null)
}

# For external DNS mode: output what ACM expects so the user can create records manually.
output "acm_dns_validation_records" {
  value = [
    for dvo in tolist(aws_acm_certificate.app_cert.domain_validation_options) : {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  ]
}
