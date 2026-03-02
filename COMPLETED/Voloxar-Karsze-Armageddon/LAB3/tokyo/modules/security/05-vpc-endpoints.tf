resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "vpc_endpoint_sg-${var.env_prefix}"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  tags = {
    Name = "sg-vpc-end-${var.env_prefix}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_in" {
  description        = "Allow endpoint traffic"
  security_group_id  = aws_security_group.vpc_endpoint_sg.id
  cidr_ipv4          = "0.0.0.0/0"
  from_port          = 443
  to_port            = 443
  ip_protocol        = "tcp"

  tags = {
    Name = "${var.env_prefix}-vpc_end_in"
  }
}

resource "aws_vpc_security_group_egress_rule" "vpc_endpoint_out" {
  security_group_id = aws_security_group.vpc_endpoint_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = {
    Name = "${var.env_prefix}-vpc_end_out"
  }
}