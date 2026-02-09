# bonus_c.tf -
# Explanation: Chewbacca builds his public-facing cantina entrance — secure, monitored, and scalable.

############################################
# ALB Security Group
############################################
# Explanation: The bouncer at the door — only HTTPS traffic allowed in.
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg01"
  description = "Security group for Chewbacca ALB"
  vpc_id      = module.network.vpc_id

  tags = {
    Name = "${var.project_name}-alb-sg01"
  }
}

# ALB Security Group Rules
resource "aws_security_group_rule" "alb_ingress_https" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS from internet"
}

resource "aws_security_group_rule" "alb_ingress_http" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP from internet"
}

resource "aws_security_group_rule" "alb_egress_to_ec2" {
  security_group_id        = aws_security_group.alb.id
  type                     = "egress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = module.network.app_security_group_id # CHANGED: Use network module output
  description              = "Allow ALB to EC2 on app port"
}

############################################
# Application Load Balancer
############################################
resource "aws_lb" "chewbacca_alb01" {
  name               = "${var.project_name}-alb01"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [module.network.public_subnet_id, module.network.public_subnet_2_id] # CHANGED: Use network module output

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb01"
  }
}

############################################
# Target Group
############################################
resource "aws_lb_target_group" "chewbacca_tg01" {
  name     = "${var.project_name}-tg01"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id # Already fixed

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-tg01"
  }
}

# Attach EC2 instances to Target Group
resource "aws_lb_target_group_attachment" "chewbacca_tg_attachment01" {
  target_group_arn = aws_lb_target_group.chewbacca_tg01.arn
  target_id        = module.compute.instance_id # CHANGED: Use compute module output
  port             = var.app_port
}

############################################
# ALB Listeners
############################################
# HTTP Listener (redirects to HTTPS)
resource "aws_lb_listener" "chewbacca_http_listener01" {
  load_balancer_arn = aws_lb.chewbacca_alb01.arn
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

# HTTPS Listener
# HTTPS Listener with Origin Cloaking (corrected syntax)
resource "aws_lb_listener" "chewbacca_https_listener01" {
  load_balancer_arn = aws_lb.chewbacca_alb01.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.chewbacca_acm_cert01.arn

  # Default action: 403 Forbidden (origin cloaking)
  default_action {
    type = "fixed-response"
    
    fixed_response {
      content_type = "text/plain"
      message_body = "403 Forbidden: Missing or invalid X-Chewbacca-Growl header"
      status_code  = "403"
    }
  }
  
  # NO "rule" blocks directly here - use aws_lb_listener_rule resource instead

  depends_on = [
    aws_acm_certificate_validation.chewbacca_acm_validation01_dns_bonus
  ]
}

# Separate rule resource
resource "aws_lb_listener_rule" "chewbacca_https_rule01" {
  listener_arn = aws_lb_listener.chewbacca_https_listener01.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chewbacca_tg01.arn
  }

  condition {
    http_header {
      http_header_name = "X-Chewbacca-Growl"
      values           = ["mdcYLQtpJJuDYqn0X0YvKqg37XDA2s9b"]  # Your secret value
    }
  }
}

############################################
# WAF for ALB (Regional)
############################################
resource "aws_wafv2_web_acl" "chewbacca_alb_waf01" {
  name        = "${var.project_name}-alb-waf01"
  description = "WAF for Chewbacca ALB"
  scope       = "REGIONAL"

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
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-alb-waf01"
    sampled_requests_enabled   = true
  }
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "chewbacca_alb_waf_assoc01" {
  resource_arn = aws_lb.chewbacca_alb01.arn
  web_acl_arn  = aws_wafv2_web_acl.chewbacca_alb_waf01.arn
}

############################################
# CloudWatch Alarm for ALB 5xx Errors
############################################

# SNS Topic for Alarms
resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-alarms"

  tags = {
    Name = "${var.project_name}-alarms"
  }
}
resource "aws_cloudwatch_metric_alarm" "chewbacca_alb_5xx_alarm01" {
  alarm_name          = "${var.project_name}-alb-5xx-alarm01"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors ALB 5xx errors"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions = {
    LoadBalancer = aws_lb.chewbacca_alb01.arn_suffix
  }

  tags = {
    Name = "${var.project_name}-alb-5xx-alarm01"
  }
}