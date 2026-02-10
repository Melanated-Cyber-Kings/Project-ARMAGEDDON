
########################################################################################################
# Launch Template
############################################################################################################
resource "aws_launch_template" "lab1_lt" {
  name_prefix   = "${local.name_prefix}-LT"
  image_id      = "ami-004ae243f24da3d27" # baked in AMI with app and CW agent
  instance_type = var.ec2_instance_type
  vpc_security_group_ids = [aws_security_group.ec2_sg01.id]
  # user_data = filebase64("user_data.sh")

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile01.name
  }
 
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.name_prefix}-LT"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
##############################################
# Target Groups
##############################################
# ########## TARGET GROUP ##########
resource "aws_lb_target_group" "lab1_tg" {
  name     = "${local.name_prefix}-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.lab1_vpc01.id
  target_type = "instance"


  health_check {
    enabled             = true
    # interval            = 30
    # path                = "/"
    # protocol            = "HTTP"
    # healthy_threshold   = 5
    # unhealthy_threshold = 2
    # timeout             = 5
    # matcher             = "200"
  }


  tags = {
    Name    = "${local.name_prefix}-target-group"
    }
}
############################################
### Load Balancer
############################################
resource "aws_lb" "lab1_alb" {
  name               = "${local.name_prefix}-alb01"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_alb.id]
  subnets            = [
    aws_subnet.public_subnets[0].id,
    aws_subnet.public_subnets[1].id,
    # aws_subnet.private_1.id,
    # aws_subnet.private_2.id,
  ]

   access_logs {
    bucket  = aws_s3_bucket.alb_logs_bucket01.bucket
    prefix  = var.alb_access_logs_prefix
    enabled = var.enable_alb_access_logs
  }

  enable_deletion_protection = false
#Lots of death and suffering here, make sure it's false

  tags = {
    Name = "${local.name_prefix}-lab1-alb"
  }
}
    
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lab1_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "redirect"
    redirect {
      protocol   = "HTTPS"
      port       = 443
      status_code = "HTTP_301"
    }
  }
  depends_on = [ aws_acm_certificate_validation.cert ]
}

# Commented out HTTPS for lab 1c until get port 80 working.
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.lab1_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lab1_tg.arn
  }
}

############################################################################
### ALB Security Group
############################################################################
resource "aws_security_group" "allow_alb" {
  name        = "${local.name_prefix}-lab1-alb-sg"
  description = "Allow LB Http(s) inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.lab1_vpc01.id

  tags = {
    Name = "${local.name_prefix}-lab1-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_lb" {
  security_group_id = aws_security_group.allow_alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_lb" {
  security_group_id = aws_security_group.allow_alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ec2_http" {
  security_group_id = aws_security_group.allow_alb.id
  referenced_security_group_id  = aws_security_group.ec2_sg01.id
 
  from_port = 80
  ip_protocol = "tcp"
  to_port   = 80  
}
#############################################
### Auto Scaling Group
#############################################
resource "aws_autoscaling_group" "lab1_asg" {
  name_prefix           = "${local.name_prefix}-auto-scaling-group"
  min_size              = 1
  max_size              = 6
  desired_capacity      = 1
  vpc_zone_identifier   = [
    aws_subnet.private_subnets[0].id,
    aws_subnet.private_subnets[1].id
  ]
  # where is the asg health check config from (for autohealing)
  health_check_type          = "ELB"
  # shorten values for demo purposes (optional)
  default_cooldown   = 60
  default_instance_warmup = 60
  health_check_grace_period  = 120
  force_delete               = true
  target_group_arns          = [aws_lb_target_group.lab1_tg.arn]

# using latest rather than default version for simplicity
  launch_template {
    id      = aws_launch_template.lab1_lt.id
    version = "$Latest"
  }


#   enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]


#   # Instance protection for launching
#   initial_lifecycle_hook {
#     name                  = "instance-protection-launch"
#     lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
#     default_result        = "CONTINUE"
#     heartbeat_timeout     = 60
#     notification_metadata = "{\"key\":\"value\"}"
#   }


#   # Instance protection for terminating
#   initial_lifecycle_hook {
#     name                  = "scale-in-protection"
#     lifecycle_transition  = "autoscaling:EC2_INSTANCE_TERMINATING"
#     default_result        = "CONTINUE"
#     heartbeat_timeout     = 300
#   }


  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-instance"
    propagate_at_launch = true
  }


#   tag {
#     key                 = "Environment"
#     value               = "Production"
#     propagate_at_launch = true
#   }
}


### Auto Scaling Policy
resource "aws_autoscaling_policy" "lab1-scaling-policy" {
  name                   = "${local.name_prefix}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.lab1_asg.name


  policy_type = "TargetTrackingScaling"
  estimated_instance_warmup = 120


  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 75.0
  }
}


### Enabling Instance Scale-In Protection
resource "aws_autoscaling_attachment" "lab1-asg-attachment" {
  autoscaling_group_name = aws_autoscaling_group.lab1_asg.name
  lb_target_group_arn   = aws_lb_target_group.lab1_tg.arn
}


#############################################
#############################################
# WAFv2 Web ACL (Basic managed rules)
############################################

resource "aws_wafv2_web_acl" "lab1_waf01" {
  count = var.enable_waf ? 1 : 0

  name  = "${var.project_name}-waf01"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf01"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
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
      metric_name                = "${var.project_name}-waf-common"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Name = "${var.project_name}-waf01"
  }
}

# UPDATED: Pointing to your lab1_alb
resource "aws_wafv2_web_acl_association" "lab1_waf_assoc01" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_lb.lab1_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.lab1_waf01[0].arn
}

############################################
# CloudWatch Alarm: ALB 5xx -> SNS
############################################

resource "aws_cloudwatch_metric_alarm" "waf_alb_5xx_alarm01" {
  alarm_name          = "${var.project_name}-alb-5xx-alarm01"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alb_5xx_evaluation_periods
  threshold           = var.alb_5xx_threshold
  period              = var.alb_5xx_period_seconds
  statistic           = "Sum"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  # UPDATED: Pointing to your lab1_alb
  dimensions = {
    LoadBalancer = aws_lb.lab1_alb.arn_suffix
  }

  alarm_actions = [aws_sns_topic.lab1c_bonus_b_sns_topic01.arn]

  tags = {
    Name = "${var.project_name}-alb-5xx-alarm01"
  }
}

############################################
# CloudWatch Dashboard
############################################

resource "aws_cloudwatch_dashboard" "lab1_dashboard01" {
  dashboard_name = "${var.project_name}-dashboard01"

  dashboard_body = jsonencode({
    widgets = [
      {
        type  = "metric"
        x     = 0
        y     = 0
        width = 12
        height = 6
        properties = {
          metrics = [
            # UPDATED: Pointing to your lab1_alb
            [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.lab1_alb.arn_suffix ],
            [ ".", "HTTPCode_ELB_5XX_Count", ".", aws_lb.lab1_alb.arn_suffix ]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Lab ALB: Requests + 5XX"
        }
      },
      {
        type  = "metric"
        x     = 12
        y     = 0
        width = 12
        height = 6
        properties = {
          metrics = [
            # UPDATED: Pointing to your lab1_alb
            [ "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.lab1_alb.arn_suffix ]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Lab ALB: Target Response Time"
        }
      }
    ]
  })
}