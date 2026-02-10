resource "aws_db_subnet_group" "this" {
  name       = "${var.env_prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "${var.env_prefix}-db-subnet-group"
  }
}
