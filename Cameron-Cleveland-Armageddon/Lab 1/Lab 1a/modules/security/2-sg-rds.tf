resource "aws_security_group" "rds_sg" {
  name        = "rds-lab-1a"
  description = "Allow inbound traffic and all outbound traffic to the rds"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env_prefix}-rds-sg"
  }
}

# Rule 1: Allow from Tokyo EC2 security group (using your existing variable)
resource "aws_vpc_security_group_ingress_rule" "rds_tokyo_ec2" {
  description                  = var.tcp_ingress_rule.description
  security_group_id            = aws_security_group.rds_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id  # Tokyo EC2 SG
  from_port                   = var.tcp_ingress_rule.port
  ip_protocol                 = "tcp"
  to_port                     = var.tcp_ingress_rule.port

  tags = {
    Name = "${var.env_prefix}-tcp-tokyo"
  }
}

# Rule 2: NEW - Allow from São Paulo VPC CIDR (10.103.0.0/16) for Lab 3A
resource "aws_vpc_security_group_ingress_rule" "rds_sao_paulo_ipv4" {
  description       = "MySQL from São Paulo VPC for Lab 3A"
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = "10.103.0.0/16"  # São Paulo VPC CIDR
  from_port         = var.tcp_ingress_rule.port  # 3306
  ip_protocol       = "tcp"
  to_port           = var.tcp_ingress_rule.port  # 3306

  tags = {
    Name = "${var.env_prefix}-tcp-sp"
  }
}

resource "aws_vpc_security_group_egress_rule" "rds_all_outbound" {
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}