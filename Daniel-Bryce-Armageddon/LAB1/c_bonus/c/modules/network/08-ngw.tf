resource "aws_eip" "nat" {
  domain           = "vpc"
  
  tags = {
    Name = "${var.env_prefix}-nat"
  }

  depends_on = [ aws_internet_gateway.main ] # explicit dependency
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "${var.env_prefix}-gw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}