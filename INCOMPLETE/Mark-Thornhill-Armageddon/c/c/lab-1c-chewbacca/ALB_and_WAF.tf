############################################
# 1. Application Load Balancer (ALB)
############################################

resource "aws_lb" "chewbacca_alb01" {
  count = var.is_lab_active ? 1 : 0
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.chewbacca_ec2_sg01.id] # Reusing EC2 SG for simplicity
  subnets            = aws_subnet.chewbacca_public_subnets[*].id

  access_logs {
      bucket  = aws_s3_bucket.chewbacca_alb_logs_bucket01[0].bucket
      prefix  = var.alb_access_logs_prefix
      enabled = var.enable_alb_access_logs
  }
  tags = {
    Name = "${var.project_name}-alb"
  }
}

############################################
# 2. Target Group & Listener
############################################

resource "aws_lb_target_group" "chewbacca_tg01" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.chewbacca_vpc01.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# HTTPS Listener (Port 443)
resource "aws_lb_listener" "chewbacca_https_listener" {
  load_balancer_arn = aws_lb.chewbacca_alb01[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chewbacca_tg01.arn
  }
}

# HTTP Listener (Port 80) - Redirects to HTTPS
resource "aws_lb_listener" "chewbacca_http_listener" {
  load_balancer_arn = aws_lb.chewbacca_alb01[0].arn
  port              = "80"
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

resource "aws_lb_target_group_attachment" "chewbacca_tg_attach01" {
  target_group_arn = aws_lb_target_group.chewbacca_tg01.arn
  target_id        = aws_instance.chewbacca_ec201.id
  port             = 80
}

############################################
# 3. Web Application Firewall (WAF)
############################################

resource "aws_wafv2_web_acl" "chewbacca_waf01" {
  # The Switch: 1 = Create, 0 = Skip
  count = var.is_lab_active ? 1 : 0  
  name        = "${var.project_name}-waf"
  description = "WAF for Chewbacca ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "chewbaccaWAF"
    sampled_requests_enabled   = true
  }

  # Basic Rule: AWS Managed Common Rule Set
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
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
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "chewbacca_waf_assoc" {
  # Count is used to conditionally create this association based on the valud of "enable_waf" variable
  count        = var.enable_waf ? 1 : 0
  resource_arn = aws_lb.chewbacca_alb01[0].arn
  web_acl_arn  = aws_wafv2_web_acl.chewbacca_waf01[0].arn
  }