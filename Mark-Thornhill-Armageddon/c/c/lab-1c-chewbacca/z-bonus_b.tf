############################################
# Route 53 & ACM (DNS + TLS)
############################################

resource "aws_route53_zone" "main" {
  count = var.manage_route53_in_terraform ? 1 : 0
  name  = var.domain_name
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  subject_alternative_names = ["*.${var.domain_name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.manage_route53_in_terraform ? aws_route53_zone.main[0].zone_id : var.route53_hosted_zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "app_alias" {
  count   = var.is_lab_active ? 1 : 0
  zone_id = var.manage_route53_in_terraform ? aws_route53_zone.main[0].zone_id : var.route53_hosted_zone_id
  name    = "${var.app_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.chewbacca_alb01[0].dns_name
    zone_id                = aws_lb.chewbacca_alb01[0].zone_id
    evaluate_target_health = true
  }
}

############################################
# Monitoring & Dashboards
############################################

resource "aws_cloudwatch_dashboard" "enterprise_monitor" {
  dashboard_name = "${var.project_name}-enterprise-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.chewbacca_alb01[0].arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB Traffic (Total Requests)"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["Lab/RDSApp", "DBConnectionErrors"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "DB Errors (Wookiee Growls)"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-${var.project_name}"
  retention_in_days = var.waf_log_retention_days
}

resource "aws_wafv2_web_acl_logging_configuration" "main" {
  count                   = var.enable_waf ? 1 : 0
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  # Notice: to reference the WAF using the [0] index
  resource_arn            = aws_wafv2_web_acl.chewbacca_waf01[0].arn
}