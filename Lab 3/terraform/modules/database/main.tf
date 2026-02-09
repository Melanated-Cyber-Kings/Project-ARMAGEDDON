# Based on the database/main.tf example
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

resource "aws_db_instance" "database" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0.35"
  instance_class         = "db.t3.micro"
  identifier             = "${var.name_prefix}-database"
  db_name                = "chewbaccamedical"
  username               = var.db_username
  password               = var.db_password
  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  
  storage_encrypted      = true
  multi_az               = false # Set to true for production
  publicly_accessible    = false
  
  backup_retention_period = 7
  skip_final_snapshot    = true # For lab only - set to false in production
  
  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-database"
  })
}
