# Reference the existing RDS secret
data "aws_secretsmanager_secret" "rds" {
  name = "lab-1a/rds/mysql"
}
