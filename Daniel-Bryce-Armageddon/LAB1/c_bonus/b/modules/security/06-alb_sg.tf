resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-${var.env_prefix}"
  description = "Allow inbound traffic to Armageddon vpc"
  vpc_id      = var.vpc_id

  tags = {
    Name = "alb-sg-${var.env_prefix}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb-http" {
  description = "HTTP from anywhere"
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80

## tags to name the security group rule
   tags = {
     Name = "HTTP from anywhere"
   }
}

resource "aws_vpc_security_group_ingress_rule" "alb-https" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow HTTPS from anywhere"

  ## tags to name the security group rule
   tags = {
     Name = "HTTPS from anywhere"
   }
}

resource "aws_vpc_security_group_egress_rule" "alb-outbound" {
  description                  = "Allow ALB to forward to EC2 on port 80"
  security_group_id = aws_security_group.alb_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id
  ip_protocol = "tcp"
  from_port = 80
  to_port = 80
}