resource "aws_vpc" "liberdade_vpc01" {
  cidr_block           = "10.102.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "liberdade-vpc-sp" }
}

resource "aws_subnet" "liberdade_private_subnet01" {
  vpc_id                  = aws_vpc.liberdade_vpc01.id
  cidr_block              = "10.102.1.0/24"
  availability_zone       = "sa-east-1a"
  tags                    = { Name = "liberdade-private-1a" }
  map_public_ip_on_launch = false
}

resource "aws_subnet" "liberdade_private_subnet02" {
  vpc_id                  = aws_vpc.liberdade_vpc01.id
  cidr_block              = "10.102.2.0/24"
  availability_zone       = "sa-east-1c"
  tags                    = { Name = "liberdade-private-1c" }
  map_public_ip_on_launch = false
}


resource "aws_security_group" "liberdade_ec2_sg" {
  name        = "liberdade-ec2-sg"
  description = "Security group for stateless compute in Sao Paulo"
  vpc_id      = aws_vpc.liberdade_vpc01.id

  ingress { #needed for CLI verification in Lab 3
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # For a lab, you can use 0.0.0.0/0
    # For high security, you'd use the specific AWS IP range for your region
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.liberdade_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Sao Paulo ALB Security Group
resource "aws_security_group" "liberdade_alb_sg" {
  name        = "liberdade-alb-sg"
  description = "Allow HTTP inbound"
  vpc_id      = aws_vpc.liberdade_vpc01.id

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

resource "aws_subnet" "liberdade_public_subnet01" {
  vpc_id                  = aws_vpc.liberdade_vpc01.id
  cidr_block              = "10.102.10.0/24"
  availability_zone       = "sa-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "liberdade-public-1a" }
}

resource "aws_subnet" "liberdade_public_subnet02" {
  vpc_id                  = aws_vpc.liberdade_vpc01.id
  cidr_block              = "10.102.20.0/24"
  availability_zone       = "sa-east-1c"
  map_public_ip_on_launch = true
  tags                    = { Name = "liberdade-public-1c" }
}


resource "aws_internet_gateway" "liberdade_gateway" {
  vpc_id   = aws_vpc.liberdade_vpc01.id
  tags     = { Name = "liberdade-gateway" }
}

# Security Group for the endpoints
resource "aws_security_group" "ssm_endpoint_sg" {
  vpc_id = aws_vpc.liberdade_vpc01.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.102.0.0/16"]
  }
}

#  The Trio of Endpoints
resource "aws_vpc_endpoint" "ssm_service" {
  for_each            = toset(["ssm", "ssmmessages", "ec2messages"])
  vpc_id              = aws_vpc.liberdade_vpc01.id
  service_name        = "com.amazonaws.sa-east-1.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.liberdade_private_subnet01.id, aws_subnet.liberdade_private_subnet02.id]
  security_group_ids  = [aws_security_group.ssm_endpoint_sg.id]
}

