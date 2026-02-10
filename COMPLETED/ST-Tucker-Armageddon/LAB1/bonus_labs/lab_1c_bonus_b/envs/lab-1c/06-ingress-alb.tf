###############################################################################
# Bonus C — Public ALB + TLS + WAF + Observability
###############################################################################

locals {
  bonus_b_fqdn = "${var.app_subdomain}.${var.domain_name}"
}

##############################
# ACM Certificate (DNS validation via Route53)
##############################

resource "aws_acm_certificate" "app_cert" {
  domain_name       = local.bonus_b_fqdn
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Convert domain_validation_options (a set) into a map for for_each
locals {
  acm_dvo = {
    for dvo in aws_acm_certificate.app_cert.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

resource "aws_route53_record" "acm_validation" {
  for_each = var.enable_route53 ? local.acm_dvo : {}

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "app_cert" {
  count = var.enable_route53 ? 1 : 0

  certificate_arn         = aws_acm_certificate.app_cert.arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}


##############################
# Allow ALB -> EC2
##############################

# Should already be allowed via security module variable alb_to_ec2_port.
# No reason to duplicate it here.
# Should be removed to avoid confusion.

# resource "aws_security_group_rule" "ec2_allow_from_alb" {
#   type                     = "ingress"
#   description              = "Allow ALB to reach EC2 app port"
#   security_group_id        = module.security.ec2_sg_id
#   from_port                = var.app_port
#   to_port                  = var.app_port
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.alb_sg.id
# }

##############################
# Application Load Balancer
##############################

resource "aws_lb" "app_alb" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [module.security.alb_sg_id]

  # Requires two public subnets
  subnets = module.vpc.public_subnet_ids

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

##############################
# Target Group
##############################

resource "aws_lb_target_group" "app_tg" {
  name        = "${local.name_prefix}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
  }

  tags = {
    Name = "${local.name_prefix}-tg"
  }
}

##############################
# Attach Private EC2 to TG
##############################

resource "aws_lb_target_group_attachment" "ec2_attach" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = module.ec2.ec2_id
  port             = var.app_port
}

##############################
# Listeners
##############################

# HTTP -> HTTPS redirect
resource "aws_lb_listener" "http_80" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS listener forwards to target group
resource "aws_lb_listener" "https_443" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  # With Route53 validation enabled, Terraform will wait for issuance and use the validated cert.
  # If enable_route53=false, ACM must be validated manually before apply will succeed.
  certificate_arn = var.enable_route53 ? aws_acm_certificate_validation.app_cert[0].certificate_arn : aws_acm_certificate.app_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

##############################
# Route53: app.<domain> -> ALB
##############################

resource "aws_route53_record" "app_alias" {
  count = var.enable_route53 ? 1 : 0

  zone_id = var.route53_zone_id
  name    = local.bonus_b_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
}

##############################
# WAFv2: managed baseline + attach to ALB
##############################

resource "aws_wafv2_web_acl" "alb_waf" {
  name  = "${local.name_prefix}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-waf-common"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "alb_waf_assoc" {
  resource_arn = aws_lb.app_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.alb_waf.arn
}

##############################
# CloudWatch Alarm: ALB 5xx -> SNS
##############################

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.name_prefix}-alb-5xx"
  alarm_description   = "ALB 5xx spike alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alb_5xx_evaluation_periods
  period              = var.alb_5xx_period_seconds
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  dimensions = {
    LoadBalancer = aws_lb.app_alb.arn_suffix
  }

  alarm_actions = [module.cloudwatch.sns_topic_arn]
  ok_actions    = [module.cloudwatch.sns_topic_arn]
}

##############################
# CloudWatch Dashboard
##############################

resource "aws_cloudwatch_dashboard" "alb_dashboard" {
  dashboard_name = "${local.name_prefix}-alb-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          region = var.region

          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.app_alb.arn_suffix, { "stat" : "Sum" }],
            [".", "HTTPCode_ELB_5XX_Count", ".", ".", { "stat" : "Sum" }]
          ]

          period = 300
          title  = "ALB Requests and ELB 5xx"

          # CloudWatch API validation wants this present
          annotations = {}
        }
      }
    ]
  })
}

