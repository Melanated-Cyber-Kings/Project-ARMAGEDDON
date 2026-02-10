resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.main.id
  cidr_block       = var.public_subnet_cidr_1
  availability_zone = var.avail_zone_1 
  map_public_ip_on_launch = true   # Allow public IPs to be assigned

  tags = {
    Name = "${var.env_prefix}-public-subnet-1a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id = aws_vpc.main.id
  cidr_block       = var.public_subnet_cidr_2
  availability_zone = var.avail_zone_2 
  map_public_ip_on_launch = true   # Allow public IPs to be assigned

  tags = {
    Name = "${var.env_prefix}-public-subnet-1c"
  }
}

############# Private Subnets ##########################
resource "aws_subnet" "private_1a" {
  vpc_id = aws_vpc.main.id
  cidr_block       = var.private_subnet_cidr_1
  availability_zone = var.avail_zone_1  # AZ A pour EC2
  

  tags = {
    Name = "${var.env_prefix}-private-subnet-1a"
  }
}

resource "aws_subnet" "private_2a" {
  vpc_id = aws_vpc.main.id
  cidr_block       = var.private_subnet_cidr_2
  availability_zone = var.avail_zone_2 # AZ C pour RDS
  
  tags = {
    Name = "${var.env_prefix}-private-subnet-1c"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id = aws_vpc.main.id
  cidr_block       = var.private_subnet_cidr_3
  availability_zone = var.avail_zone_3  # failover
  

  tags = {
    Name = "${var.env_prefix}-private-subnet-1d"
  }
}
########################################################