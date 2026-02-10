# bonus_b.tf
# Explanation: Chewbacca builds his public-facing cantina entrance — secure, monitored, and scalable.

############################################
# ALB Security Group
############################################
# Explanation: The bouncer at the door — only HTTPS traffic allowed in.
resource "aws_security_group" "chewbacca_alb_sg01" {
  name        = "${var.project_name}-alb-sg01"
  description = "Security group for Chewbacca ALB"
  vpc_id      = data.aws_vpc.chewbacca_vpc01.id

  tags = {
    Name = "${var.project_name}-alb-sg01"
  }
}

# ALB Security Group Rules
resource "aws_security_group_rule" "alb_ingress_https" {
  security_group_id = aws_security_group.chewbacca_alb_sg01.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS from internet"
}

resource "aws_security_group_rule" "alb_ingress_http" {
  security_group_id = aws_security_group.chewbacca_alb_sg01.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP from internet"
}

resource "aws_security_group_rule" "alb_egress_to_ec2" {
  security_group_id        = aws_security_group.chewbacca_alb_sg01.id
  type                     = "egress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.chewbacca_ec2_sg01.id
  description              = "Allow ALB to EC2 on app port"
}

############################################
# Application Load Balancer
############################################
resource "aws_lb" "chewbacca_alb01" {
  name               = "${var.project_name}-alb01"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.chewbacca_alb_sg01.id]
  subnets            = aws_subnet.chewbacca_public_subnets[*].id

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
  vpc_id   = aws_vpc.chewbacca_vpc01.id

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
  target_id        = aws_instance.chewbacca_ec201_private_bonus.id
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
resource "aws_lb_listener" "chewbacca_https_listener01" {
  load_balancer_arn = aws_lb.chewbacca_alb01.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.chewbacca_acm_cert01.arn

   default_action {
    type = "fixed-response"  # ← CHANGE from "forward" to "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access denied - Origin cloaking enforced"
      status_code  = "403"
    }
  }


  # Ensure certificate is validated before creating listener
  depends_on = [
    aws_acm_certificate_validation.chewbacca_acm_validation01_dns_bonus
  ]
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
  alarm_actions       = [aws_sns_topic.chewbacca_sns_topic01.arn]

  dimensions = {
    LoadBalancer = aws_lb.chewbacca_alb01.arn_suffix
  }

  tags = {
    Name = "${var.project_name}-alb-5xx-alarm01"
  }
}