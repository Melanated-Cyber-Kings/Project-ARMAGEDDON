############################################
# VPC + Internet Gateway 
############################################

# Network VPC 
resource "aws_vpc" "lab1_vpc01" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc01"
  }
}

# Explanation: Needed to allow users in to access the app on the EC2 from the internet.
resource "aws_internet_gateway" "igw01" {
  vpc_id = aws_vpc.lab1_vpc01.id

  tags = {
    Name = "${local.name_prefix}-igw01"
  }
}
