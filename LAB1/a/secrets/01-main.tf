provider "aws" {
  region = var.region
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name = "${var.env_prefix}/rds/mysql"
}

data "aws_secretsmanager_secret" "my_secret" {
  name = "${var.env_prefix}/rds/mysql"
}