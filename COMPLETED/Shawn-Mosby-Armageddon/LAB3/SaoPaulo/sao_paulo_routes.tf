# Explanation: Liberdade knows the way to Shinjuku—Tokyo CIDR routes go through the TGW corridor.
resource "aws_route" "liberdade_to_tokyo_route01" {
  route_table_id         = aws_route_table.liberdade_private_rt01.id
  destination_cidr_block = data.terraform_remote_state.tokyo.outputs.vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.liberdade_tgw01.id
}

resource "aws_route_table" "liberdade_private_rt01" {
  vpc_id = aws_vpc.liberdade_vpc01.id
  tags   = { Name = "liberdade-private-rt" }
}

resource "aws_route_table" "liberdade_public_rt" {
  vpc_id = aws_vpc.liberdade_vpc01.id
  tags   = { Name = "liberdade-public-rt" }
}

# Associate Private Subnet 01 (RDS resides here) added for CLI
resource "aws_route_table_association" "liberdade_priv_assoc_1" {
  subnet_id      = aws_subnet.liberdade_private_subnet01.id
  route_table_id = aws_route_table.liberdade_private_rt01.id
}

# Associate Private Subnet 02 (RDS resides here) added for CLI
resource "aws_route_table_association" "liberdade_priv_assoc_2" {
  subnet_id      = aws_subnet.liberdade_private_subnet02.id
  route_table_id = aws_route_table.liberdade_private_rt01.id
}

resource "aws_route_table_association" "liberdade_public_a" {
  subnet_id      = aws_subnet.liberdade_public_subnet01.id
  route_table_id = aws_route_table.liberdade_public_rt.id
}

resource "aws_route_table_association" "liberdade_public_c" {
  subnet_id      = aws_subnet.liberdade_public_subnet02.id
  route_table_id = aws_route_table.liberdade_public_rt.id
}

resource "aws_nat_gateway" "liberdade_nat" {
  allocation_id = aws_eip.liberdade_nat_eip.id
  # NAT MUST sit in a public subnet to work
  subnet_id     = aws_subnet.liberdade_public_subnet01.id 
  # Reference your existing IGW name here:
  depends_on    = [aws_internet_gateway.liberdade_gateway] 
  tags          = { Name = "liberdade-nat" }
}

resource "aws_eip" "liberdade_nat_eip" {
  domain = "vpc"
}


# Give the Public Route Table access to the Internet
resource "aws_route" "liberdade_public_internet_route" {
  route_table_id         = aws_route_table.liberdade_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  # Use your existing IGW name:
  gateway_id             = aws_internet_gateway.liberdade_gateway.id 
}

# Tell Private Subnets to use the NAT for the Internet
resource "aws_route" "liberdade_private_nat_route" {
  route_table_id         = aws_route_table.liberdade_private_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.liberdade_nat.id
}
