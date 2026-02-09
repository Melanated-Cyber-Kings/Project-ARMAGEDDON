###############################################################################
# alb.tf
# Module: ingress (Lab-1C Bonus C)
###############################################################################

locals {
  name_prefix = var.env_prefix
  app_fqdn    = "${var.app_subdomain}.${var.domain_name}"

  is_route53_managed  = var.dns_mode == "route53_managed"
  is_route53_existing = var.dns_mode == "route53_existing"
  is_route53          = local.is_route53_managed || local.is_route53_existing

  # HTTPS listener is always safe in Route53 modes (Terraform can validate ACM automatically).
  # In external mode, enable only after cert is ISSUED.
  enable_https_listener = local.is_route53 || var.enable_https_in_external
}

resource "aws_lb" "app_alb" {
  name               = "${local.name_prefix}-alb"
  load_balancer_type = "application"

  # For Lab-1C Bonus C, we want internet-facing ALB. The default is "internet-facing", so we can omit the scheme or set it explicitly.
  # If you want an internal ALB, set scheme to "internal". For internet-facing, you can either omit it or set it to "internet-facing".
  # If you want to switch between internal and internet-facing, you can use a variable or condition. For example:
  # scheme = var.is_internal ? "internal" : "internet-facing"
  # For simplicity, we will set it to "internet-facing" for this lab. If you want to make it configurable, 
  # you can use a variable like var.alb_scheme and set it to either "internal" or "internet-facing".
  # If you want to make it configurable, you can do something like this: 
  # scheme             = "internet-facing"
  # For Lab-1C Bonus C, we want internet-facing ALB. Set internal to false for internet-facing, true for internal. 

  # Note: The "internal" argument is a boolean that determines whether the ALB is internal or internet-facing. 
  # If internal is true, the ALB is internal. If internal is false, the ALB is internet-facing.

  # This section is important because it determines the accessibility of your ALB. An internet-facing ALB can be accessed from the 
  # internet, while an internal ALB can only be accessed from within the VPC.
  #
  # If you want to create an internal ALB, set internal to true and ensure that your subnets are private. 
  # If you want to create an internet-facing ALB, set internal to false and ensure that your subnets are public.

  # I ran into an issue when initially using the "scheme" argument to set the ALB to "internet-facing". The error was:
  # "Error: creating LB: InvalidScheme: The scheme of the load balancer must be internal or internet-facing"
  # Online I found that the scheme argument can be an issue depending on the AWS provider version. In some versions, the "scheme" argument is not supported or has specific requirements.
  # To avoid this issue, I switched to using the "internal" argument, which is a boolean and basically it worked without any issues. 
  # So for this lab, I will use the "internal" argument to set the ALB to internet-facing by setting internal to false.

  # Reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb#internal 
  # Reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb#scheme
  # Reference: https://aws.amazon.com/premiumsupport/knowledge-center/elb-internal-internet-facing/


  internal = false

  security_groups = [var.alb_sg_id]
  subnets         = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "${local.name_prefix}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${local.name_prefix}-tg"
  }
}

resource "aws_lb_target_group_attachment" "ec2_attach" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = var.target_instance_id
  port             = var.app_port
}
