###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: rds
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

output "port" {
  description = "Port of the RDS DB"
  value       = aws_db_instance.mysql.port
}


output "address" {
  description = "Host of the RDS instance"
  value       = aws_db_instance.mysql.address
}

output "db_identifier" {
  description = "RDS DB instance identifier"
  value       = aws_db_instance.mysql.identifier
}
