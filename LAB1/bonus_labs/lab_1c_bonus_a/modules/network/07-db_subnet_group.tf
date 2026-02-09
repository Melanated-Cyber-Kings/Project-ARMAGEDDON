###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: network
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

resource "aws_db_subnet_group" "this" {
  name       = "${var.env_prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "${var.env_prefix}-db-subnet-group"
  }
}
