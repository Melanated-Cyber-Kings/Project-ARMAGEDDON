###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: network
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

resource "aws_db_subnet_group" "this" {

  name        = "${lower(var.env_prefix)}-db-subnet-group"
  description = "DB subnet group for ${var.env_prefix}"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.env_prefix}-db-subnet-group"
    }
  )
}
