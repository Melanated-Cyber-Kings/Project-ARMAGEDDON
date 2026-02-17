# 1. We need a static IP for the NAT
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.name_prefix}-nat-eip" }
}

# 2. The NAT Gateway itself
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Place it in the first public subnet

  tags = { Name = "${var.name_prefix}-nat-gw" }

  # To ensure proper ordering, it depends on the IGW
  depends_on = [aws_internet_gateway.main]
}