resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  enable_dns_hostnames = var.dns_hostnames
  enable_dns_support = var.dns_support # Optional default is true


  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

