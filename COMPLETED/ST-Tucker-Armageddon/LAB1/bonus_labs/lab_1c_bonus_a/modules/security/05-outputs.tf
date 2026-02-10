###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: security
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

# Output for EC2 Security Group ID
output "ec2_sg_id" {
  value       = aws_security_group.ec2_sg.id
  description = "ID of the EC2 security group"
}

# Output for RDS Security Group ID
output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

# Output for VPC Endpoint Security Group ID
output "vpce_sg_id" {
  description = "Security group for VPC interface endpoints"
  value       = aws_security_group.endpoints_sg.id
}


###############################################################################