data "aws_lb" "existing_alb" {
  name = "chewbacca-alb01"
}

data "aws_security_group" "existing_alb_sg" {
  filter {
    name   = "tag:Name"
    values = ["chewbacca-alb-sg01"]  # Changed from chewbacca-alb-sg
  }
}

data "aws_route53_zone" "existing" {
  zone_id = var.existing_zone_id
}

data "aws_vpc" "main" {
  id = var.existing_vpc_id
}

data "aws_lb_listener" "existing_https_listener" {
  load_balancer_arn = data.aws_lb.existing_alb.arn
  port              = 443
}

data "aws_lb_target_group" "existing_tg" {
  name = "chewbacca-tg01"
}
