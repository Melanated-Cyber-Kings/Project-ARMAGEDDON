############# Public Subnets ##########################

resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.main.id
  cidr_block       = var.public_subnet_cidr
  availability_zone = var.avail_zone_1 # Specify AZ
  
  #lab1c, no more public ips
  map_public_ip_on_launch = true   # Allow public IPs to be assigned

  tags = {
    Name = "${var.env_prefix}-public-subnet-1a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id = aws_vpc.main.id
  cidr_block       = var.public_subnet_cidr2
  availability_zone = var.avail_zone_2 # Specify AZ
  
  #lab1c, no more public ips
  map_public_ip_on_launch = true   # Allow public IPs to be assigned

  tags = {
    Name = "${var.env_prefix}-public-subnet-1b"
  }
}






############# Private Subnets ##########################
resource "aws_subnet" "private_a" {
  vpc_id = aws_vpc.main.id
  cidr_block       = var.private_subnet_cidr_1
  availability_zone = var.avail_zone_1  # Specify AZ
  

  tags = {
    Name = "${var.env_prefix}-private-subnet-1a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id = aws_vpc.main.id
  cidr_block       = var.private_subnet_cidr_2
  availability_zone = var.avail_zone_2  # Specify AZ
  

  tags = {
    Name = "${var.env_prefix}-private-subnet-1b"
  }
}
########################################################

