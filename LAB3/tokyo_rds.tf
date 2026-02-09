resource "aws_db_subnet_group" "shinjuku_db_subnet_group" {
  name       = "shinjuku-db-subnet-group"
  subnet_ids = [aws_subnet.chewbacca_private_subnet01.id, aws_subnet.chewbacca_private_subnet02.id]
  tags       = { Name = "shinjuku-db-subnet-group" }
}

resource "aws_security_group" "chewbacca_rds_sg01" {
  name        = "shinjuku-rds-sg"
  description = "Allow MariaDB/MySQL from Tokyo and Sao Paulo"
  vpc_id      = aws_vpc.chewbacca_vpc01.id

  # Rule 1: Allow local Tokyo App Tier
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"] #added 10.102.0.0/16 for Sao Paulo CLI verification
  }

  # Rule 2: Allow Sao Paulo App Tier (Liberdade) via TGW
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.102.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "shinjuku_medical_db" {
  allocated_storage      = 20
  engine                 = "mariadb"
  engine_version         = "10.11"
  instance_class         = "db.t3.micro"
  db_name                = "medical_records"
  username               = "admin"
  password               = "shinjuku2026!" # Use Secrets Manager in production!
  parameter_group_name   = "default.mariadb10.11"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.shinjuku_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.chewbacca_rds_sg01.id]
  publicly_accessible    = false
  tags                   = { Name = "shinjuku-medical-rds" }
}