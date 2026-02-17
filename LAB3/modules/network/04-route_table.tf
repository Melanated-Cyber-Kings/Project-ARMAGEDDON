# ---------------------------------------------------------
# 1. PUBLIC ROUTING
# ---------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${var.name_prefix}-public-rtb" }
}


  resource "aws_route" "public_internet_access" {
    route_table_id         = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.main.id
  }

# Associate Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------
# 2. PRIVATE ROUTING
# ---------------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${var.name_prefix}-private-rtb" }
}


resource "aws_route" "private_nat_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

# Associate Private APP Subnets
resource "aws_route_table_association" "private_app" {
  count          = length(var.private_subnet_cidrs_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private.id
}

# Associate Private DB Subnets
resource "aws_route_table_association" "private_db" {
  count          = length(var.private_subnet_cidrs_db)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route" "tgw_corridor" {
  count                  = var.tgw_route_config != null ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = var.tgw_route_config.destination_cidr
  transit_gateway_id     = var.tgw_route_config.tgw_id
}