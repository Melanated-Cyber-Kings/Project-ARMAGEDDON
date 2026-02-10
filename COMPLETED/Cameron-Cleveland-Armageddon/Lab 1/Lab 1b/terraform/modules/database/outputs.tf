output "db_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

output "db_port" {
  value = aws_db_instance.mysql.port
}

output "db_name" {
  value = aws_db_instance.mysql.db_name
}

output "db_username" {
  value     = aws_db_instance.mysql.username
  sensitive = true
}

output "kms_key_arn" {
  value = aws_kms_key.rds.arn
}

output "rds_instance_id" {
  value = aws_db_instance.mysql.id
}