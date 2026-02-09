output "db_endpoint" {
  description = "Connection endpoint for the database"
  value       = aws_db_instance.database.endpoint
  sensitive   = true
}

output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.database.id
}
