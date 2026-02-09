###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: security
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

resource "aws_security_group" "rds" {
  name        = "${var.env_prefix}-rds-sg"
  description = "RDS security group; DB access only from EC2 security group"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.env_prefix}-rds-sg"
    }
  )
}

# Allow DB traffic ONLY from the EC2 Security Group (SG-to-SG)
resource "aws_security_group_rule" "rds_ingress_db_from_ec2" {
  type                     = "ingress"
  description              = "DB access from EC2 SG"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2.id
  security_group_id        = aws_security_group.rds.id
}

# Allow outbound (responses/AWS-managed communications)
resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  description       = "All outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
}
