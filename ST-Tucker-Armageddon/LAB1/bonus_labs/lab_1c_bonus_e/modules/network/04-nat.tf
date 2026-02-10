###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: network
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

# ============================================================
# Lab 1C — Network: NAT Gateway for Private Subnets
# 
# ============================================================

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.env_prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id

  # NAT must live in a PUBLIC subnet
  subnet_id = aws_subnet.public_a.id

  # Ensure Internet Gateway is created before NAT Gateway
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.env_prefix}-nat-gw"
  }
}
