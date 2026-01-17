# Determine which configuration to use
locals {
  # Use HA lists if provided, otherwise use legacy single values
  use_ha_config = length(var.public_subnet_cidrs) > 0
  
  availability_zones = local.use_ha_config ? var.availability_zones : [var.avail_zone]
  public_cidrs      = local.use_ha_config ? var.public_subnet_cidrs : [var.public_subnet_cidr]
  private_cidrs     = local.use_ha_config ? var.private_subnet_cidrs : [var.private_subnet_cidr]
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  
  tags = {
    Name    = "${var.env_prefix}-vpc"
    Project = var.project
  }
}

# Public Subnets (supports both HA and single)
resource "aws_subnet" "public" {
  count = length(local.public_cidrs)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_cidrs[count.index]
  availability_zone       = local.availability_zones[count.index % length(local.availability_zones)]
  map_public_ip_on_launch = true
  
  tags = {
    Name    = "${var.env_prefix}-public-${count.index + 1}"
    Project = var.project
    Type    = "public"
    AZ      = local.availability_zones[count.index % length(local.availability_zones)]
  }
}

# Private Subnets (supports both HA and single)
resource "aws_subnet" "private" {
  count = length(local.private_cidrs)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_cidrs[count.index]
  availability_zone = local.availability_zones[count.index % length(local.availability_zones)]
  
  tags = {
    Name    = "${var.env_prefix}-private-${count.index + 1}"
    Project = var.project
    Type    = "private"
    AZ      = local.availability_zones[count.index % length(local.availability_zones)]
  }
}
