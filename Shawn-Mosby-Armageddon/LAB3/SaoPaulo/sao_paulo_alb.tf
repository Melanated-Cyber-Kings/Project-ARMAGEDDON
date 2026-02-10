# São Paulo ALB (The Spoke)
resource "aws_lb" "liberdade_alb" {
  name               = "liberdade-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.liberdade_alb_sg.id]
  subnets            = [aws_subnet.liberdade_public_subnet01.id, aws_subnet.liberdade_public_subnet02.id]
}

# Sao Paulo Listener
resource "aws_lb_listener" "liberdade_http" {
  load_balancer_arn = aws_lb.liberdade_alb.arn
  port              = "80"
  protocol          = "HTTP"

  # default_action {   #for lab 3a
  #   type             = "forward"
  #   target_group_arn = aws_lb_target_group.liberdade_tg.arn
  # }
  default_action { #added for lab 3b. ALB's deny everything by default, unless the secret header is present
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied: Use the Global Edge Entry Point."
      status_code  = "403"
    }
  }
}

resource "aws_lb_target_group" "liberdade_tg" {
  name     = "liberdade-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.liberdade_vpc01.id

  health_check {
    path                = "/records/save/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
