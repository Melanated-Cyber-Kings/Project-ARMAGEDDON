resource "aws_security_group" "ec2_sg" {
  name        = "ec2-${var.env_prefix}"
  description = "Security group for EC2"
  vpc_id      = var.vpc_id

  tags = {
    Name = "sg-ec2-${var.env_prefix}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_http" {
  description        = "Allow HTTP traffic"
  security_group_id  = aws_security_group.ec2_sg.id
  cidr_ipv4          = "0.0.0.0/0"
  from_port          = 80
  to_port            = 80
  ip_protocol        = "tcp"

  tags = {
    Name = "${var.env_prefix}-http"
  }
}

resource "aws_vpc_security_group_egress_rule" "ec2_all_outbound" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
