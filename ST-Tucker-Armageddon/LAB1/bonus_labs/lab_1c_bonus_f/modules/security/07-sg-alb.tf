###############################################################################
# COMPONENT: security
# PURPOSE: Public ALB security group + ALB -> EC2 rule
###############################################################################

resource "aws_security_group" "alb_sg" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Public ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "ALB egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-sg"
  })
}

###############################################################################
# Allow ALB -> EC2 app traffic
###############################################################################

resource "aws_security_group_rule" "alb_to_ec2" {
  type        = "ingress"
  description = "Allow ALB to reach EC2 app port"
  protocol    = "tcp"
  from_port   = var.alb_to_ec2_port
  to_port     = var.alb_to_ec2_port

  security_group_id        = aws_security_group.ec2_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}
