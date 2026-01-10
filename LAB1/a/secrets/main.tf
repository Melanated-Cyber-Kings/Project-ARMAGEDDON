provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name = "lab-1a/rds/mysql"
}
