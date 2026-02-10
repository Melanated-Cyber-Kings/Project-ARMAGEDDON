###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: rds
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

output "port" {
  description = "Port of the RDS DB"
  value       = aws_db_instance.mysql.port
}


output "address" {
  description = "Host of the RDS instance"
  value       = aws_db_instance.mysql.address
}