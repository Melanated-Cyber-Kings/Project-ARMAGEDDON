###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: security
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

output "ec2_sg_id" {
  description = "Security group ID for the EC2 instance."
  value       = aws_security_group.ec2.id
}

output "rds_sg_id" {
  description = "Security group ID for the RDS instance."
  value       = aws_security_group.rds.id
}
