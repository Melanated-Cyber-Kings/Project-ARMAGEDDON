###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: rds
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

resource "aws_db_instance" "mysql" {
  identifier = "lab-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  multi_az = var.multi_az

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.rds_security_group_id]

  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false
}

######################################################################################

resource "aws_ssm_parameter" "db_config" {
  for_each = {
    endpoint = aws_db_instance.mysql.endpoint
    port     = aws_db_instance.mysql.port
    name     = aws_db_instance.mysql.db_name
  }

  name  = "/${var.env_prefix}/db/${each.key}"
  type  = "String"
  value = each.value
  tags = {
    Lab = "incident-response"
  }
}
