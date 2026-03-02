resource "aws_security_group" "ec2_sg" {
  name        = "ec2-${var.env_prefix}"
  description = "Security group for EC2"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env_prefix}-sg-ec2"
  }
}


resource "aws_vpc_security_group_ingress_rule" "ec2_http" {
  description        = "Allow HTTP from ALB only"
  security_group_id  = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.alb_sg01.id
  from_port          = 80
  to_port            = 80
  ip_protocol        = "tcp"

  tags = {
    Name = "${var.env_prefix}-http-from-alb"
  }
}



#lab1c replaced with new security rule with alb in mind
# resource "aws_vpc_security_group_ingress_rule" "ec2_http" {
#   description        = "Allow http traffic"
#   security_group_id  = aws_security_group.ec2_sg.id
#   cidr_ipv4          = "0.0.0.0/0"
#   from_port          = 80
#   to_port            = 80
#   ip_protocol        = "tcp"

#   tags = {
#     Name = "${var.env_prefix}-http"
#   }
# }

#lab1c no more ssh
# resource "aws_vpc_security_group_ingress_rule" "ec2_ssh" {
#   description        = "Allow ssh traffic"
#   security_group_id  = aws_security_group.ec2_sg.id
#   cidr_ipv4          = "0.0.0.0/0"
#   from_port          = 22
#   to_port            = 22
#   ip_protocol        = "tcp"

#   tags = {
#     Name = "${var.env_prefix}-ssh"
#   }
# }


resource "aws_vpc_security_group_egress_rule" "ec2_all_outbound" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# TODO: students ensure EC2 security group allows inbound from ALB SG on this port (rule above)