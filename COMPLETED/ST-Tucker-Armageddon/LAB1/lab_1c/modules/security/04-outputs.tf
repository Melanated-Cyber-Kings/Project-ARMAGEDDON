###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: security
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

output "ec2_sg_id" {
  value       = aws_security_group.ec2_sg.id
  description = "ID of the EC2 security group"
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}
