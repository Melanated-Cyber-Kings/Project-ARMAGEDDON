resource "aws_security_group" "rds_sg" {
  name        = "rds-lab-1c"
  description = "Allow inbound traffic and all outbound traffic to the rds"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env_prefix}-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds-http_ipv4" {
  description = var.tcp_ingress_rule.description
  security_group_id = aws_security_group.rds_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  #cidr_ipv4        = var.tcp_ingress_rule.cidr
  from_port         = var.tcp_ingress_rule.port
  ip_protocol       = "tcp"
  to_port           = var.tcp_ingress_rule.port

## tags to name the security group rule
   tags = {
     Name = "${var.env_prefix}-tcp"
   }
}

resource "aws_vpc_security_group_egress_rule" "rds_all_outbound" {
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_security_group_rule" "rds_ingress_from_saopaulo" {
  description = "Allow MySQL from Sao Paulo VPC via TGW"
  
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = [var.saopaulo_vpc_cidr] 
  
  security_group_id = aws_security_group.rds_sg.id
  
  # Add lifecycle to prevent destroy/recreate issues
  lifecycle {
    create_before_destroy = true
  }
}