###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# LAB:   LAB-2A
# COMPONENT: ingress / edge
#
# PURPOSE
# - CloudFront is the only public entrypoint.
# - ALB is "internet-facing" but functionally private:
#     1) ALB SG allows inbound ONLY from CloudFront origin-facing prefix list
#     2) ALB listener requires a secret custom header; otherwise returns 403
#
# NOTES
# - This file assumes your baseline resources exist in this root module:
#     module.vpc, module.ec2, module.security, module.cloudwatch (SNS)
# - This file intentionally does NOT publish Route53 records to the ALB.
###############################################################################



###############################################################################
# Secret origin header (defense-in-depth)
###############################################################################
resource "random_password" "origin_header_value" {
  length  = 32
  special = false
}



###############################################################################
# Ensure EC2 allows inbound from the ALB SG on the app port
###############################################################################
# resource "aws_security_group_rule" "ec2_allow_from_alb_cf_sg" {
#   type                     = "ingress"
#   description              = "Allow ALB (CloudFront-only SG) to reach EC2 app port"
#   security_group_id        = module.security.ec2_sg_id
#   from_port                = var.app_port
#   to_port                  = var.app_port
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.alb_cloudfront_only.id
# }

###############################################################################
# ACM Certificate (us-east-1) — used by BOTH CloudFront and ALB
# - One certificate avoids duplicate DNS validation records and CNAME collisions.
# - Includes apex + app SAN.
###############################################################################
locals {
  app_fqdn = "${var.app_subdomain}.${var.domain_name}"
}

resource "aws_acm_certificate" "edge_cert" {
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = [local.app_fqdn]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-edge-cert"
  })
}

# Convert domain_validation_options (a set) into a map for for_each
locals {
  edge_cert_dvo = {
    for dvo in aws_acm_certificate.edge_cert.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

resource "aws_route53_record" "edge_cert_validation" {
  for_each = var.enable_route53 ? local.edge_cert_dvo : {}

  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "edge_cert" {
  provider = aws.us_east_1
  count    = var.enable_route53 ? 1 : 0

  certificate_arn         = aws_acm_certificate.edge_cert.arn
  validation_record_fqdns = [for r in aws_route53_record.edge_cert_validation : r.fqdn]
}

###############################################################################
# Application Load Balancer + Target Group + Listener behavior
###############################################################################
resource "aws_lb" "app_alb" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"

  # IMPORTANT: This is the CloudFront-only SG
  #security_groups = [aws_security_group.alb_cloudfront_only.id]
  security_groups = [module.security.alb_sg_id]

  # Requires two public subnets
  subnets = module.vpc.public_subnet_ids

  # Replace the ALB instead of modifying in-place to ensure new SG and 
  # subnet associations take effect.

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-alb"
  })
}

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

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-tg"
  })
}

resource "aws_lb_target_group_attachment" "ec2_attach" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = module.ec2.ec2_id
  port             = var.app_port
}

# HTTP → HTTPS redirect
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

# HTTPS listener default: fixed 403
# Allow rule below forwards only when secret origin header matches.
resource "aws_lb_listener" "https_443" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  certificate_arn = var.enable_route53 ? aws_acm_certificate_validation.edge_cert[0].certificate_arn : aws_acm_certificate.edge_cert.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}

###############################################################################
# Listener rule: only forward when the header matches (CloudFront adds this)
###############################################################################
# variable "origin_header_name" {
#   description = "Header name CloudFront adds; ALB requires it to forward."
#   type        = string
#   default     = "X-Origin-Verify"
# }

resource "aws_lb_listener_rule" "allow_only_cloudfront_header" {
  listener_arn = aws_lb_listener.https_443.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  condition {
    http_header {
      http_header_name = var.origin_header_name
      values           = [random_password.origin_header_value.result]
    }
  }
}

###############################################################################
# CloudWatch Alarm: ALB 5xx → SNS
###############################################################################
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


