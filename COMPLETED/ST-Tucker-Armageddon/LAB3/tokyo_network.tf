resource "aws_vpc" "chewbacca_vpc01" {
  cidr_block           = "10.101.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "shinjuku-vpc-tokyo" }
}

resource "aws_subnet" "chewbacca_private_subnet01" {
  vpc_id            = aws_vpc.chewbacca_vpc01.id
  cidr_block        = "10.101.1.0/24"
  availability_zone = "ap-northeast-1a"
  tags              = { Name = "shinjuku-private-1a" }
}

resource "aws_subnet" "chewbacca_private_subnet02" {
  vpc_id            = aws_vpc.chewbacca_vpc01.id
  cidr_block        = "10.101.2.0/24"
  availability_zone = "ap-northeast-1c"
  tags              = { Name = "shinjuku-private-1c" }
}

resource "aws_route_table" "chewbacca_private_rt01" {
  vpc_id = aws_vpc.chewbacca_vpc01.id
  tags   = { Name = "shinjuku-private-rt" }
}

resource "aws_route_table" "chewbacca_public_rt01" {
  vpc_id = aws_vpc.chewbacca_vpc01.id
  tags   = { Name = "shinjuku-public-rt" }
}

resource "aws_security_group" "shinjuku_ec2_sg" {
  name        = "shinjuku-ec2-sg"
  description = "Allow traffic from Tokyo ALB"
  vpc_id      = aws_vpc.chewbacca_vpc01.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.shinjuku_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Tokyo ALB Security Group
resource "aws_security_group" "shinjuku_alb_sg" {
  name        = "shinjuku-alb-sg"
  description = "Allow HTTP inbound"
  vpc_id      = aws_vpc.chewbacca_vpc01.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "chewbacca_public_subnet01" {
  vpc_id                  = aws_vpc.chewbacca_vpc01.id
  cidr_block              = "10.101.10.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "shinjuku-public-1a" }
}

resource "aws_subnet" "chewbacca_public_subnet02" {
  vpc_id                  = aws_vpc.chewbacca_vpc01.id
  cidr_block              = "10.101.20.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true
  tags                    = { Name = "shinjuku-public-1c" }
}

resource "aws_internet_gateway" "shinjuku_igw" {
  vpc_id = aws_vpc.chewbacca_vpc01.id
  tags   = { Name = "shinjuku-igw" }
}

# resource "aws_route_table" "shinjuku_public_rt" {
#   vpc_id = aws_vpc.chewbacca_vpc01.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.shinjuku_igw.id
#   }
#   tags = { Name = "shinjuku-public-rt" }
# }

# resource "aws_route_table_association" "shinjuku_pub_assoc_1" {
#   subnet_id      = aws_subnet.chewbacca_public_subnet01.id
#   route_table_id = aws_route_table.shinjuku_public_rt.id
# }

# resource "aws_route_table_association" "shinjuku_pub_assoc_2" {
#   subnet_id      = aws_subnet.chewbacca_public_subnet02.id
#   route_table_id = aws_route_table.shinjuku_public_rt.id
# }

# resource "aws_internet_gateway" "shinjuku_gateway" {
#   vpc_id   = aws_vpc.chewbacca_vpc01.id
#   tags     = { Name = "shinjuku-igw" }
# }
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "shinjuku-nat-eip" }
}


resource "aws_nat_gateway" "shinjuku_nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.chewbacca_public_subnet01.id # Place it in the first public subnet

  # It depends on the IGW
  depends_on = [aws_internet_gateway.shinjuku_igw]
}