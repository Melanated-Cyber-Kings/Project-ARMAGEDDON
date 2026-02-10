resource "aws_lb_listener_rule" "allow_cloudfront" {
  listener_arn = var.https_listener_arn
  priority     = 1 

  action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }

  condition {
    http_header {
      http_header_name = var.header_name
      values           = [var.header_value]
    }
  }
}

resource "aws_lb_listener_rule" "deny_direct" {
  listener_arn = var.https_listener_arn
  priority     = 99 

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied: Direct origin access is forbidden. Use the Edge URL."
      status_code  = "403"
    }
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}