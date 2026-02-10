#####################################################################
# 1c_bonus-A
#######################################################
# Design goals
#   EC2 is private (no public IP)
#   No SSH required (use SSM Session Manager)
#   Private subnets don’t need NAT to talk to AWS control-plane services 
#   Use VPC Interface Endpoints for:
#     SSM, EC2Messages, SSMMessages (Session Manager)
#     CloudWatch Logs
#     Secrets Manager
#     KMS (optional but realistic)
# Use S3 Gateway Endpoint (common “gotcha” for private environments)
# Tighten IAM: GetSecretValue only for your secret, GetParameter(s) only for your path

# Note: If you remove NAT entirely, OS package installs can be tricky unless repos are reachable (often via S3). This skeleton gives you S3 endpoint and leaves NAT as optional “student choice.” In many orgs, teams use golden AMIs or image pipelines to avoid yum/apt internet needs in private subnets.
######################################################################


# # 1. Define the Security Group
# resource "aws_security_group" "vpc_endpoint_sg" {
#   name        = "${local.name_prefix}-vpc-endpoint-sg"
#   description = "Security group for VPC Endpoints to allow HTTPS from VPC"
#   vpc_id      = ws_vpc.lab1_vpc01.id # Replace with your VPC ID

#   tags = {
#     Name = "${local.name_prefix}-vpc-endpoint-sg01"
#   }
# }

# # 2. Allow Inbound HTTPS (Port 443) from the VPC CIDR
# resource "aws_vpc_security_group_ingress_rule" "allow_https_from_vpc" {
#   security_group_id = aws_security_group.vpc_endpoint_sg.id
  
#   cidr_ipv4   = var.vpc_cidr # Replace with your actual VPC CIDR
#   from_port   = 443
#   to_port     = 443
#   ip_protocol = "tcp"
#   description = "Allow HTTPS inbound from VPC CIDR"
# }

# # 3. (Optional) Example of attaching this SG to an Interface Endpoint
# resource "aws_vpc_endpoint" "example_endpoint" {
#   vpc_id              = "vpc-xxxxxxxxxxxxxxxxx"
#   service_name        = "com.amazonaws.us-east-1.ec2" # Example service
#   vpc_endpoint_type   = "Interface"
#   security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
#   private_dns_enabled = true
# }

############################################
# Lab 1a/b sg
############################################
############################################
# Security Groups (EC2 + RDS)
############################################

# Explanation: EC2 SG is Chewbacca’s bodyguard—only let in what you mean to.
resource "aws_security_group" "ec2_sg01" {
  name        = "${local.name_prefix}-ec2-sg01"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.lab1_vpc01.id



  tags = {
    Name = "${local.name_prefix}-ec2-sg01"
  }
}

## TODO: student adds inbound rules (HTTP 80, SSH 22 from their IP)
## Commenting out for lab 1c where no SSH or HTTP is needed
##
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.ec2_sg01.id
  #referenced_security_group_id  = aws_security_group.allow_alb.id
  
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.ec2_sg01.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

################################################################################
## Egress Rules for EC2 SG
################################################################################

 # TODO: student ensures outbound allows DB port to RDS SG (or allow all outbound)
resource "aws_vpc_security_group_egress_rule" "allow_to_rds" {
  security_group_id = aws_security_group.ec2_sg01.id
  referenced_security_group_id  = aws_security_group.rds_sg01.id

  from_port   = 3306
  ip_protocol = "tcp"
  to_port     = 3306
}

resource "aws_vpc_security_group_egress_rule" "allow_to_https" {
  security_group_id = aws_security_group.ec2_sg01.id
  # source_security_group_id  = aws_security_group.vpc_endpoints.id
 
  from_port = 443
  ip_protocol = "tcp"
  to_port   = 443
  cidr_ipv4 = "0.0.0.0/0"
}



# Explanation: RDS SG is the Rebel vault—only the app server gets a keycard.
resource "aws_security_group" "rds_sg01" {
  name        = "${local.name_prefix}-rds-sg01"
  description = "RDS security group"
  vpc_id      = aws_vpc.lab1_vpc01.id

  # TODO: student adds inbound MySQL 3306 from aws_security_group ec2_sg01.id

  tags = {
    Name = "${local.name_prefix}-rds-sg01"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_mysql_from_ec2" {
  security_group_id = aws_security_group.rds_sg01.id
  referenced_security_group_id  = aws_security_group.ec2_sg01.id
  from_port   = 3306
  ip_protocol = "tcp"
  to_port     = 3306
}












