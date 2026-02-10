# Elastic IP for NAT
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# NAT Gateway in a public subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_a.id  # must be a public subnet

tags = {
    Name = "${var.env_prefix}-nat"
  }
}

