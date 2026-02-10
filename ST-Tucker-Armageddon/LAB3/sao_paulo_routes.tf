# Explanation: Liberdade knows the way to Shinjuku—Tokyo CIDR routes go through the TGW corridor.
resource "aws_route" "liberdade_to_tokyo_route01" {
  provider               = aws.saopaulo
  route_table_id         = aws_route_table.liberdade_private_rt01.id
  destination_cidr_block = "10.101.0.0/16" # Tokyo VPC CIDR (students supply)
  transit_gateway_id     = aws_ec2_transit_gateway.liberdade_tgw01.id
}

resource "aws_route_table" "liberdade_private_rt01" {
  provider = aws.saopaulo
  vpc_id   = aws_vpc.liberdade_vpc01.id
  tags     = { Name = "liberdade-private-rt" }
}

resource "aws_route_table" "liberdade_public_rt" {
  provider = aws.saopaulo
  vpc_id   = aws_vpc.liberdade_vpc01.id
  tags     = { Name = "liberdade-public-rt" }
}

# Associate Private Subnet 01 (RDS resides here) added for CLI
resource "aws_route_table_association" "liberdade_priv_assoc_1" {
  provider       = aws.saopaulo
  subnet_id      = aws_subnet.liberdade_private_subnet01.id
  route_table_id = aws_route_table.liberdade_private_rt01.id
}

# Associate Private Subnet 02 (RDS resides here) added for CLI
resource "aws_route_table_association" "liberdade_priv_assoc_2" {
  provider       = aws.saopaulo
  subnet_id      = aws_subnet.liberdade_private_subnet02.id
  route_table_id = aws_route_table.liberdade_private_rt01.id
}

resource "aws_route_table_association" "liberdade_public_a" {
  provider       = aws.saopaulo
  subnet_id      = aws_subnet.liberdade_public_subnet01.id
  route_table_id = aws_route_table.liberdade_public_rt.id
}

resource "aws_route_table_association" "liberdade_public_c" {
  provider       = aws.saopaulo
  subnet_id      = aws_subnet.liberdade_public_subnet02.id
  route_table_id = aws_route_table.liberdade_public_rt.id
}