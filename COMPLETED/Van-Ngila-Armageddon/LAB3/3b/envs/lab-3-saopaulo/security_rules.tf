# Security Group Rules (applied after groups are created)

# Refine EC2 SG egress - restrict to VPC endpoints after they exist
resource "aws_security_group_rule" "ec2_to_vpc_endpoints_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.liberdade_ec2_sg.id
  
  # Reference the VPC endpoints security group
  source_security_group_id = aws_security_group.liberdade_vpc_endpoints_sg.id
  
  description = "HTTPS to VPC endpoints"
}

# Add MySQL egress to Tokyo RDS
resource "aws_security_group_rule" "ec2_to_tokyo_rds_mysql" {
  type              = "egress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.liberdade_ec2_sg.id
  
  # Tokyo VPC CIDR via TGW
  cidr_blocks       = [local.tokyo_vpc_cidr]
  
  description = "MySQL to Tokyo RDS via TGW"
}

# Refine VPC endpoints SG ingress - restrict to EC2 SG
resource "aws_security_group_rule" "vpc_endpoints_from_ec2_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.liberdade_vpc_endpoints_sg.id
  
  # Reference the EC2 security group
  source_security_group_id = aws_security_group.liberdade_ec2_sg.id
  
  description = "HTTPS from EC2 instances"
}