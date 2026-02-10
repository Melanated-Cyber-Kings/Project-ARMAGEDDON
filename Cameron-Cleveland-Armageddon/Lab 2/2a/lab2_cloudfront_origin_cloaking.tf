# Origin cloaking for Lab 2A

# CloudFront prefix list
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# Allow ALB inbound only from CloudFront prefix list
resource "aws_security_group_rule" "alb_ingress_cloudfront_only" {
  security_group_id = data.aws_security_group.existing_alb_sg.id
  type              = "ingress"
  description       = "Allow CloudFront only"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
}

# ALB Listener Rule: Require custom header from CloudFront
resource "aws_lb_listener_rule" "require_origin_header" {
  listener_arn = data.aws_lb_listener.existing_https_listener.arn
  priority     = 100

  condition {
    http_header {
      http_header_name = "X-Chewbacca-Growl"
      values           = ["mdcYLQtpJJuDYqn0X0YvKqg37XDA2s9b"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = data.aws_lb_target_group.existing_tg.arn
  }
}

# Default rule: Block everything else with 403
/*resource "aws_lb_listener_rule" "default_block" {
  listener_arn = data.aws_lb_listener.existing_https_listener.arn
  priority     = 50000  # Lowest priority

  /*condition {
    path_pattern {
      values = ["/*"]
    }
  }

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Access denied - Origin cloaking enforced"
      status_code  = "403"
    }
  }
}*/
