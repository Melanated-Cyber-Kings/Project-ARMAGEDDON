output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.mysql.id
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.mysql.endpoint
}

output "db_address" {
  description = "RDS address"
  value       = aws_db_instance.mysql.address
}

output "db_identifier" {
  description = "RDS identifier"
  value       = aws_db_instance.mysql.identifier
}

output "multi_az" {
  description = "Whether Multi-AZ is enabled"
  value       = aws_db_instance.mysql.multi_az
}

output "db_status" {
  description = "RDS status"
  value       = aws_db_instance.mysql.status
}

output "db_instance_class" {
  description = "RDS instance class"
  value       = aws_db_instance.mysql.instance_class
}

output "availability_zone" {
  description = "RDS availability zone"
  value       = aws_db_instance.mysql.availability_zone
}
