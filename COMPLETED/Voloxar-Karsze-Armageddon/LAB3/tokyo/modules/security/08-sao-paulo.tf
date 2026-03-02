# Explanation: Tokyo’s vault opens only to approved clinics—Liberdade gets DB access, the public gets nothing.
resource "aws_security_group_rule" "shinjuku_rds_ingress_from_liberdade01" {
  type              = "ingress"
  security_group_id = aws_security_group.rds_sg.id
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"

  cidr_blocks =  [var.far_dest_cidr]                #["10.x.x.x/xx"] # Sao Paulo VPC CIDR (students supply)
}