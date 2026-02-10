###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: security
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

resource "aws_security_group" "ec2" {
  name        = "${var.env_prefix}-ec2-sg"
  description = "EC2 security group for LAB workloads"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.env_prefix}-ec2-sg"
    }
  )
}

# SSH (lab default: open; tighten CIDRs as needed)
# resource "aws_security_group_rule" "ec2_ingress_ssh" {
#   type              = "ingress"
#   description       = "SSH"
#   from_port         = 22
#   to_port           = 22
#   protocol          = "tcp"
#   cidr_blocks       = var.allowed_ssh_cidrs
#   security_group_id = aws_security_group.ec2.id
# }

# HTTP (lab default: open)
resource "aws_security_group_rule" "ec2_ingress_http" {
  type              = "ingress"
  description       = "HTTP"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.allowed_http_cidrs
  security_group_id = aws_security_group.ec2.id
}

# Outbound (allow all)
resource "aws_security_group_rule" "ec2_egress_all" {
  type              = "egress"
  description       = "All outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2.id
}
