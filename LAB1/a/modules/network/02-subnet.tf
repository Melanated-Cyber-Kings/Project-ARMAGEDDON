############# Public Subnets ##########################

resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.main.id
  cidr_block       = var.public_subnet_cidr
  availability_zone = var.avail_zone # Specify AZ
  map_public_ip_on_launch = true   # Allow public IPs to be assigned

  tags = {
    Name = "${var.env_prefix}-public-subnet-1a"
  }
}
############# Private Subnets ##########################
resource "aws_subnet" "private_a" {
  vpc_id = aws_vpc.main.id
  cidr_block       = var.private_subnet_cidr
  availability_zone = var.avail_zone  # Specify AZ
  

  tags = {
    Name = "${var.env_prefix}-private-subnet-1a"
  }
}
########################################################

