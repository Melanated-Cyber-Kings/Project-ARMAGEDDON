############################################
# Target Group + Attachment
############################################

# Explanation: Target groups are Chewbacca’s “who do I forward to?” list — private EC2 lives here.
resource "aws_lb_target_group" "targetgroup1" {
  name     = "${var.project}-tg01"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Deregistration delay prevents abrupt closes
  #deregistration_delay = 60

  # TODO: students set health check path to something real (e.g., /health)
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project}-targetgroup1"
  }
}

# Explanation: Chewbacca personally introduces the ALB to the private EC2 — “this is my friend, don’t shoot.”
resource "aws_lb_target_group_attachment" "targetgroup1_attachment" {
  target_group_arn = aws_lb_target_group.targetgroup1.arn
  target_id        = var.ec2_id
  port             = 80

}