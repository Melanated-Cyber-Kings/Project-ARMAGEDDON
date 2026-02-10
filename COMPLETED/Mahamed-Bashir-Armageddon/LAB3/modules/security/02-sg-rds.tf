resource "aws_security_group" "rds_sg" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Allow inbound traffic to RDS"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }
}

# RULE 1: LOCAL ACCESS (From EC2 Security Group)
resource "aws_vpc_security_group_ingress_rule" "rds_from_local_ec2" {
  description                  = "Allow Local EC2 SG"
  security_group_id            = aws_security_group.rds_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"

  tags = { Name = "${var.name_prefix}-ingress-local" }
}

# RULE 2: REMOTE ACCESS (From TGW CIDR) - [CRITICAL FOR LAB 3]
# Source: [SEIR_Foundations | 3a_lab.txt | "Tokyo RDS SG allows inbound... from São Paulo VPC CIDR"]
resource "aws_vpc_security_group_ingress_rule" "rds_from_tgw" {
  count             = var.allow_remote_cidr != null ? 1 : 0
  
  description       = "Allow Remote TGW Spoke"
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = var.allow_remote_cidr
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"

  tags = { Name = "${var.name_prefix}-ingress-remote" }
}

resource "aws_vpc_security_group_egress_rule" "rds_all_outbound" {
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}