############# Public Route table ##########################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  #default gateway route
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

#missed this, backported from lab2, fixes alb hanging
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id  # Add this if it exists
  route_table_id = aws_route_table.public.id
}



############ Private Route Table ##########################

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # No internet route required for RDS
  # AWS automatically adds the local VPC route

  tags = {
    Name = "${var.env_prefix}-private-rtb"
  }

  #lab1c, added nat for outgoing access, ec2 is now private.connection 
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
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
