# Tokyo ALB (The Hub)
resource "aws_lb" "shinjuku_alb" {
  name               = "shinjuku-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.shinjuku_alb_sg.id] # You'll need this SG too
  subnets            = [aws_subnet.chewbacca_public_subnet01.id, aws_subnet.chewbacca_public_subnet02.id]
}

# São Paulo ALB (The Spoke)
resource "aws_lb" "liberdade_alb" {
  provider           = aws.saopaulo
  name               = "liberdade-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.liberdade_alb_sg.id]
  subnets            = [aws_subnet.liberdade_public_subnet01.id, aws_subnet.liberdade_public_subnet02.id]
}

# Tokyo Listener
resource "aws_lb_listener" "shinjuku_http" {
  load_balancer_arn = aws_lb.shinjuku_alb.arn
  port              = "80"
  protocol          = "HTTP"


  # default_action { #for lab 3a
  #   type             = "forward"
  #   target_group_arn = aws_lb_target_group.shinjuku_tg.arn
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



# Sao Paulo Listener
resource "aws_lb_listener" "liberdade_http" {
  provider          = aws.saopaulo
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
resource "aws_lb_target_group" "shinjuku_tg" {
  name     = "shinjuku-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.chewbacca_vpc01.id

  health_check {
    path                = "/records/save/" # Matching your manual Python server path
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "liberdade_tg" {
  provider = aws.saopaulo
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

resource "aws_lb_listener_rule" "shinjuku_cloaking" { #added for lab 3b. ALB's deny everything by default, unless the secret header is present
  listener_arn = aws_lb_listener.shinjuku_http.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.shinjuku_tg.arn
  }

  condition {
    http_header {
      http_header_name = "X-Medical-Vault-Secret"
      values           = ["VaultSecret2026!-Compliance"]
    }
  }
}