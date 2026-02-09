###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: network
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}