output "port" {
  description = "Port of the RDS DB"
  value       = aws_db_instance.mysql.port
}


output "address" {
  description = "Host of the RDS instance"
  value = aws_db_instance.mysql.address
}