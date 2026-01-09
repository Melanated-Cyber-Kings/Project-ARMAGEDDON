resource "aws_internet_gateway" "igw-lab-1c" {
  vpc_id = aws_vpc.vpc-lab-1c.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}