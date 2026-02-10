###############################################################################
# modules/security/01-sg-ec2.tf
# EC2 Security Group + ingress rules (centralized in security module)
###############################################################################

resource "aws_security_group" "ec2_sg" {
  name        = "${var.env_prefix}-ec2-sg"
  description = "EC2 application security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name   = "${var.env_prefix}-ec2-sg"
    Module = "security"
  })
}

###############################################################################
# Ingress: ALB -> EC2 (App Port)
# NOTE: This is required for the ALB target group health checks and forwarding.
###############################################################################
resource "aws_security_group_rule" "alb_to_ec2" {
  type                     = "ingress"
  description              = "Allow ALB to reach EC2 app port"
  security_group_id        = aws_security_group.ec2_sg.id
  from_port                = var.alb_to_ec2_port
  to_port                  = var.alb_to_ec2_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
}

###############################################################################
# Egress: allow all (EC2 needs to reach AWS APIs via endpoints, RDS, etc.)
###############################################################################
resource "aws_security_group_rule" "ec2_egress_all" {
  type              = "egress"
  description       = "Allow all outbound"
  security_group_id = aws_security_group.ec2_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
