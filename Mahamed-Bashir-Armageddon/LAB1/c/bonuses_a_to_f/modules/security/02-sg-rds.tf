resource "aws_security_group" "rds_sg" {
  name        = "rds-lab-1a"
  description = "Allow inbound traffic and all outbound traffic to the rds"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds-http_ipv4" {
  description = var.tcp_ingress_rule.description
  security_group_id = aws_security_group.rds_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  
  from_port         = var.tcp_ingress_rule.port
  ip_protocol       = "tcp"
  to_port           = var.tcp_ingress_rule.port


   tags = {
     Name = "${var.name_prefix}-tcp"
   }
}

resource "aws_vpc_security_group_egress_rule" "rds_all_outbound" {
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}