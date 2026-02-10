output "rds_endpoint" {
  description = "The DNS address of the RDS instance"
   value       = replace(aws_db_instance.mysql.endpoint, ":3306", "")
}