resource "aws_lb" "alb_public" {
  name               = "${var.env_prefix}-alb-public"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  enable_deletion_protection = false

# ALB ACCESS LOGS (Bonus D)
  # access_logs {
  #   bucket  = var.alb_access_logs_bucket_name
  #   enabled = var.enable_alb_access_logs
  # }
  dynamic "access_logs" {
    for_each = var.enable_alb_access_logs ? [1] : []
    
    content {
      bucket  = var.alb_access_logs_bucket_name
      enabled = var.enable_alb_access_logs
      prefix  = var.alb_access_logs_prefix
     }
  }
  depends_on = [var.alb_logs_bucket_dependency]


  tags = {
    Name = "${var.env_prefix}-alb-public"
  }
}

# target
resource "aws_lb_target_group" "alb_private_targets"{
    name = "${var.env_prefix}-alb-targets"
    port = 80
    protocol = "HTTP"
    vpc_id= aws_vpc.main.id

    health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200-399"
    }
  

    tags = {
        Name = "${var.env_prefix}-alb_private_targets"
    }
}

resource "aws_lb_target_group_attachment" "attach" {
  target_group_arn = aws_lb_target_group.alb_private_targets.arn
  target_id        = var.ec2_id
  port = 80
}

resource "aws_lb_listener" "alb_http" {
  load_balancer_arn = aws_lb.alb_public.arn
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

resource "aws_lb_listener" "alb_https" {
  load_balancer_arn = aws_lb.alb_public.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = var.acm_certificate_arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_private_targets.arn
    
  }
  # not needed for issued certificate
  #depends_on = [ var.acm_certificate_validation_id ]
}