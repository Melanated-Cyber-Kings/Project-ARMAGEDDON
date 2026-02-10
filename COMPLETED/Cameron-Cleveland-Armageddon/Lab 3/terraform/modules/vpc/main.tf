# Create VPC - Based on the 01-main.tf pattern
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = merge(var.common_tags, {
    Name = "${var.region_name}-vpc"
  })
}

# Create Internet Gateway - Essential for public subnets
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.common_tags, {
    Name = "${var.region_name}-igw"
  })
}

# Create Public Subnets - Following the pattern from 01-main.tf
resource "aws_subnet" "public" {
  for_each = var.public_subnet_cidrs
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = var.availability_zones[index(keys(var.public_subnet_cidrs), each.key)]
  map_public_ip_on_launch = true
  
  tags = merge(var.common_tags, {
    Name = "${var.region_name}-public-${each.key}"
  })
}

# Create Private Subnets - Only if specified
resource "aws_subnet" "private" {
  for_each = var.private_subnet_cidrs
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = var.availability_zones[index(keys(var.private_subnet_cidrs), each.key)]
  
  tags = merge(var.common_tags, {
    Name = "${var.region_name}-private-${each.key}"
  })
}

# Create Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(var.common_tags, {
    Name = "${var.region_name}-public-rt"
  })
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public
  
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Create Private Route Table (will be updated later with TGW routes)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.common_tags, {
    Name = "${var.region_name}-private-rt"
  })
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {
  for_each = var.private_subnet_cidrs
  
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
