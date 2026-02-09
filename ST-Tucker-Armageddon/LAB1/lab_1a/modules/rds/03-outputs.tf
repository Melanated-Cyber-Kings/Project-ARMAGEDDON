###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: rds
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

output "endpoint" {
  description = "RDS endpoint address."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "RDS address."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS port."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Database name."
  value       = var.db_name
}
