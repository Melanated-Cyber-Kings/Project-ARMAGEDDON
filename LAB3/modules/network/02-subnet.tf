# 1. Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${var.name_prefix}-public-${count.index + 1}" }
}

# 2. Private App Subnets
resource "aws_subnet" "private_app" {
  count             = length(var.private_subnet_cidrs_app)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs_app[count.index]
  availability_zone = var.azs[count.index]

  tags = { Name = "${var.name_prefix}-private-app-${count.index + 1}" }
}

# 3. Private DB Subnets
resource "aws_subnet" "private_db" {
  count             = length(var.private_subnet_cidrs_db)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs_db[count.index]
  availability_zone = var.azs[count.index]

  tags = { Name = "${var.name_prefix}-private-db-${count.index + 1}" }
}