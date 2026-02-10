provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name = "${var.env_prefix}/rds/mysql"
}

