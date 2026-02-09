###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: VPC Endpoints security group
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

# Security group for Interface VPC Endpoints
resource "aws_security_group" "endpoints_sg" {
  name        = "${var.env_prefix}-vpce-sg"
  description = "Interface VPC endpoints: allow HTTPS from EC2"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTPS from EC2 to interface endpoints"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-vpce-sg"
  })
}
