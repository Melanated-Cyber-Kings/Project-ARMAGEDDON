output "db_endpoint" {
  description = "RDS endpoint for EC2 connections"
  value       = aws_db_instance.mysql.endpoint
}
