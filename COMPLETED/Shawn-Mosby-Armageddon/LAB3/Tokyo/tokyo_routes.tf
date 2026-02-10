# Explanation: Shinjuku returns traffic to Liberdade—because doctors need answers, not one-way tunnels.
resource "aws_route" "shinjuku_to_sp_route01" {
  route_table_id         = aws_route_table.chewbacca_private_rt01.id
  destination_cidr_block = "10.102.0.0/16" # Sao Paulo VPC CIDR (students supply)
  transit_gateway_id     = aws_ec2_transit_gateway.shinjuku_tgw01.id
}

# Associate Private Subnet 01 (RDS resides here) added for CLI
resource "aws_route_table_association" "shinjuku_priv_assoc_1" {
  subnet_id      = aws_subnet.chewbacca_private_subnet01.id
  route_table_id = aws_route_table.chewbacca_private_rt01.id
  depends_on = [aws_route_table.chewbacca_private_rt01]
}

# Associate Private Subnet 02 (RDS resides here) added for CLI
resource "aws_route_table_association" "shinjuku_priv_assoc_2" {
  subnet_id      = aws_subnet.chewbacca_private_subnet02.id
  route_table_id = aws_route_table.chewbacca_private_rt01.id
    depends_on = [aws_route_table.chewbacca_private_rt01]

}

resource "aws_route_table_association" "tokyo-public-a" {
  subnet_id      = aws_subnet.chewbacca_public_subnet01.id
  route_table_id = aws_route_table.chewbacca_public_rt01.id
}

resource "aws_route_table_association" "tokyo-public-d" {
  subnet_id      = aws_subnet.chewbacca_public_subnet02.id
  route_table_id = aws_route_table.chewbacca_public_rt01.id
}

resource "aws_route" "shinjuku_public_internet_access" {
  route_table_id         = aws_route_table.chewbacca_public_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.shinjuku_igw.id
}


