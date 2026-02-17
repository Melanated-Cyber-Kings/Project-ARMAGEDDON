resource "aws_db_subnet_group" "this" {
  count      = length(var.private_subnet_cidrs_db) > 0 ? 1 : 0
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.private_db[*].id

  tags = {
    Name = "${var.name_prefix}-db-subnet-group"
  }
}