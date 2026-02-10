resource "aws_db_instance" "mysql" {
  identifier = "lab-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"

  db_name        = var.db_name
  username = var.db_username
  password = var.db_password

  multi_az = true

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.rds_security_group_id]

  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false
}

resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/lab/db/endpoint"
  type  = "String"
  value = aws_db_instance.mysql.address # Link to your actual RDS instance
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/lab/db/name"
  type  = "String"
  value = aws_db_instance.mysql.db_name
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/lab/db/port"
  type  = "String"
  value = "3306"
}