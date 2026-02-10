resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id


  route {
    cidr_block = var.rtb_public_cidr
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.env_prefix}-public-rtb"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}




resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  

  tags = {
    Name = "${var.env_prefix}-private-rtb"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}


resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}