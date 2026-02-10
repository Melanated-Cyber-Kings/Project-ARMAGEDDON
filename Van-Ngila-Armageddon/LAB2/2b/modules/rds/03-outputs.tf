output "port" {
  description = "Port of the RDS DB"
  value       = aws_db_instance.mysql.port
}


output "address" {
  description = "Host of the RDS instance"
  value = aws_db_instance.mysql.address
}

output "db_endpoint" {
  description = "RDS endpoint (hostname:port)"
  value       = aws_db_instance.mysql.endpoint
}

output "db_address" {
  description = "RDS hostname only"
  value       = aws_db_instance.mysql.address
}

output "db_port" {
  description = "RDS port number"
  value       = aws_db_instance.mysql.port
}

output "db_name" {
  description = "RDS database name"
  value       = aws_db_instance.mysql.db_name
}