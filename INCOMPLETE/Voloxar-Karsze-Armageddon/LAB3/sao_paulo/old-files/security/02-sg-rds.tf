locals {
  rds_source_sgs = {
    ec2_sg          = aws_security_group.ec2_sg.id
    lambda_to_rds   = aws_security_group.lambda_to_rds.id
  }
}



resource "aws_security_group" "rds_sg" {
  name        = "rds-lab-1b"
  description = "Allow inbound traffic and all outbound traffic to the rds"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env_prefix}-rds-sg"
  }
}

# resource "aws_vpc_security_group_ingress_rule" "rds-tcp_ipv4" {
#   description = var.tcp_ingress_rule.description
#   security_group_id = aws_security_group.rds_sg.id
#   referenced_security_group_id = aws_security_group.ec2_sg.id

#   #cidr_ipv4        = var.tcp_ingress_rule.cidr
#   from_port         = var.tcp_ingress_rule.port
#   ip_protocol       = "tcp"
#   to_port           = var.tcp_ingress_rule.port

# ## tags to name the security group rule
#    tags = {
#      Name = "${var.env_prefix}-tcp"
#    }
# }

resource "aws_vpc_security_group_egress_rule" "rds_all_outbound" {
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#move to lambda tf
# # from Perplexity, allow rotation lambda access to database
# # https://www.perplexity.ai/search/this-is-my-main-terraform-secr-_lezldQbQmWQZzRtIm0TWg

# # Add to your Lambda (if in VPC) or create a new security group
# resource "aws_security_group" "lambda_to_rds" {
#   vpc_id = var.vpc_id  # Your VPC
#   egress {
#     from_port   = 3306
#     to_port     = 3306
#     protocol    = "tcp"
#     security_groups = [aws_security_group.rds_sg.id]
#   }

#   tags = {
#     Name = "${var.env_prefix}-rotation-lambda-sg"
#   }
# }

# resource "aws_security_group_rule" "rds_from_lambda" {
#   type                     = "ingress"
#   from_port                = 3306
#   to_port                  = 3306
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.rds_sg.id
#   source_security_group_id = aws_security_group.lambda_to_rds.id
# }

resource "aws_security_group_rule" "rds_from_sources" {
  for_each = local.rds_source_sgs
  
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = each.value
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
}