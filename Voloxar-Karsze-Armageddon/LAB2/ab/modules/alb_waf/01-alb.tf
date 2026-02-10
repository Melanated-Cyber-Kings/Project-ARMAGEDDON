############################################
# Application Load Balancer
############################################

# Explanation: The ALB is your public customs checkpoint — it speaks TLS and forwards to private targets.
resource "aws_lb" "alb01" {
  name               = "${var.project}-alb01"
  load_balancer_type = "application"
  internal           = false

  security_groups = [var.alb_sg_id]
  subnets         = var.public_subnet_ids

  # prevents premature connection close
  idle_timeout = 3600

  # TODO: students can enable access logs to S3 as a stretch goal
  # VK: Done
  dynamic "access_logs" {
    for_each = var.enable_alb_access_logs ? [1] : []
    
    content {
      bucket  = lower("${var.alb_access_logs_bucket_name}-${var.env_prefix}-alb-logs-${var.project}")
      enabled = true
      prefix  = var.alb_access_logs_prefix
    }
  }
  #depends_on = [var.alb_logs_bucket_dependency]





  tags = {
    Name = "${var.project}-alb01"
  }
}

###########################################
#ALB Listeners: HTTP -> HTTPS redirect, HTTPS -> TG
###########################################

#Explanation: HTTP listener is the decoy airlock — it redirects everyone to the secure entrance.
resource "aws_lb_listener" "http_listener01" {
  load_balancer_arn = aws_lb.alb01.arn
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

resource "aws_lb_listener" "https_listener01" {
  load_balancer_arn = aws_lb.alb01.arn
  port              = 443
  protocol          = "HTTPS"
  #ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  ssl_policy       = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn  
    }

  #moved to zone53 outputs
  #depends_on = [aws_acm_certificate_validation.chewbacca_acm_validation01]
}



# #Explanation: HTTP listener is the decoy airlock — it redirects everyone to the secure entrance.
# resource "aws_lb_listener" "http_listener01" {
#   load_balancer_arn = aws_lb.alb01.arn
#   port              = 80
#   protocol          = "HTTP"

#  default_action {
#     type             = "forward"
#     target_group_arn = var.target_group_arn  
#     }
# }


#lab2 stuff
# Explanation: ALB checks for Chewbacca’s secret growl — no growl, no service.
resource "aws_lb_listener_rule" "require_origin_header01" {
  listener_arn = aws_lb_listener.https_listener01.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }

  condition {
    http_header {
      http_header_name = "X-Chewbacca-Growl"
      values           = [var.header_value]
    }
  }
}

# Explanation: If you don’t know the growl, you get a 403 — Chewbacca does not negotiate.
resource "aws_lb_listener_rule" "default_block01" {
  listener_arn = aws_lb_listener.https_listener01.arn
  priority     = 99

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }

  condition {
    path_pattern { values = ["*"] }
  }
}