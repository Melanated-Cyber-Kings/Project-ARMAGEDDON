# ---------------------------------------------------------
# 1. PUBLIC ROUTING (The Ingress)
# ---------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${var.name_prefix}-public-rtb" }
}

# The single "Door" to the Internet
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associate ALL Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------
# 2. PRIVATE ROUTING (The Smuggler/NAT Path)
# ---------------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${var.name_prefix}-private-rtb" }
}

# The Smuggler's Run (EC2 to Internet via NAT for pip install)
resource "aws_route" "private_nat_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

# Associate ALL Private APP Subnets (The Bunker)
resource "aws_route_table_association" "private_app" {
  count          = length(var.private_subnet_cidrs_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private.id
}

# Associate ALL Private DB Subnets (The Vault)
resource "aws_route_table_association" "private_db" {
  count          = length(var.private_subnet_cidrs_db)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private.id
}