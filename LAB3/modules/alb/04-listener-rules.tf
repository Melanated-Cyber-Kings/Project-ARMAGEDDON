# RULE 1: AUTHORIZED - The Handshake matches
resource "aws_lb_listener_rule" "allow_cloudfront" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1 

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    http_header {
      http_header_name = var.header_name
      values           = [var.header_value]
    }
  }
}

# RULE 2: DENIED - Everything else (direct ALB hits)
resource "aws_lb_listener_rule" "deny_direct" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 99 # Catch-all

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