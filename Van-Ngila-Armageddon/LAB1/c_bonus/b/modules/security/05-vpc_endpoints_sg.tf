resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.env_prefix}-vpc-endpoints-sg"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env_prefix}-vpc-endpoints-sg"
  }
}

# Autoriser le trafic HTTPS (443) depuis le security group des instances EC2
resource "aws_security_group_rule" "endpoint_ingress_from_ec2" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_sg.id
  security_group_id        = aws_security_group.vpc_endpoints.id
  description              = "Allow HTTPS from EC2 instances"
}

# Autoriser tout le trafic sortant (par défaut, mais explicite)
resource "aws_security_group_rule" "endpoint_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "Allow all outbound traffic"
}
