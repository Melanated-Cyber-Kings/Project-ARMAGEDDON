# Create VPC (Based on the pattern from 01-main.tf)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = merge(var.common_tags, {
    Name = "${var.region_name}-vpc"
  })
}

# Create Subnets (Example for one public subnet - you need to loop for all)
resource "aws_subnet" "public" {
  for_each          = var.public_cidr_blocks
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = var.availability_zones[index(keys(var.public_cidr_blocks), each.key)]
  tags = merge(var.common_tags, {
    Name = "${var.region_name}-public-${each.key}"
  })
}

# Create Private Subnets ONLY if the map is not empty
resource "aws_subnet" "private" {
  for_each          = var.private_cidr_blocks
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = var.availability_zones[index(keys(var.private_cidr_blocks), each.key)]
  tags = merge(var.common_tags, {
    Name = "${var.region_name}-private-${each.key}"
  })
}

# Create Internet Gateway, Route Tables, NAT Gateway, etc. (You need to add these based on the VPC module example)
