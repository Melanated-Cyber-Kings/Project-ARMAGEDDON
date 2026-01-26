provider "aws" {
  region = var.region
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name = "${var.env_prefix}/rds/mysql"
}

data "aws_secretsmanager_secret" "my_secret" {
  name = "${var.env_prefix}/rds/mysql"
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_secret.id

  secret_string = jsonencode({
    username = var.username
    password = var.password
    #host     = var.address
    port     = var.port
    dbname   = var.dbname
  })
}
