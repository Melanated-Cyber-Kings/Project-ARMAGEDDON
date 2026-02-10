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

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}


############ Private Route Table ########################################################

resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.main.id

  # Add route to NAT Gateway for internet access
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  # AWS automatically adds the local VPC route

  tags = {
    Name = "${var.env_prefix}-private_1a-rtb" # AZ A
  }
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_1a.id
}
########################################################################################

resource "aws_route_table" "private_2a" {
  vpc_id = aws_vpc.main.id

  # Add route to NAT Gateway for internet access
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  # AWS automatically adds the local VPC route

  tags = {
    Name = "${var.env_prefix}-private_1c-rtb" # AZ C
  }
}

resource "aws_route_table_association" "private_2a" {
  subnet_id      = aws_subnet.private_2a.id
  route_table_id = aws_route_table.private_2a.id
}
###########################################################################################
resource "aws_route_table" "private_1c" {
  vpc_id = aws_vpc.main.id

  # Add route to NAT Gateway for internet access
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  
  # AWS automatically adds the local VPC route

  tags = {
    Name = "${var.env_prefix}-private_1d-rtb" # AZ D
  }
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private_1c.id
}
############################################################################################
