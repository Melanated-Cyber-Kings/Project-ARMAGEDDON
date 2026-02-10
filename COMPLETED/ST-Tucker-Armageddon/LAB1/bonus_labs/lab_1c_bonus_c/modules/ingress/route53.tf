###############################################################################
# route53.tf
# Module: ingress (Lab-1C Bonus C)
###############################################################################

locals {
  # domain_validation_options is a SET; convert to list for count/index usage
  dvo_list = tolist(aws_acm_certificate.app_cert.domain_validation_options)

  # Zone resolution
  zone_id = local.is_route53_managed ? aws_route53_zone.this[0].zone_id : var.route53_hosted_zone_id
}

resource "aws_route53_zone" "this" {
  count = local.is_route53_managed ? 1 : 0
  name  = var.domain_name
}

############################################
# ACM DNS validation records (Route53 modes)
############################################
resource "aws_route53_record" "acm_validation" {
  count = local.is_route53 ? length(local.dvo_list) : 0

  zone_id = local.zone_id

  name    = local.dvo_list[count.index].resource_record_name
  type    = local.dvo_list[count.index].resource_record_type
  ttl     = 60
  records = [local.dvo_list[count.index].resource_record_value]
}

############################################
# ALIAS record: app.<domain> -> ALB (Route53 modes)
############################################
resource "aws_route53_record" "app_alias" {
  count = local.is_route53 ? 1 : 0

  zone_id = local.zone_id
  name    = local.app_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
}
