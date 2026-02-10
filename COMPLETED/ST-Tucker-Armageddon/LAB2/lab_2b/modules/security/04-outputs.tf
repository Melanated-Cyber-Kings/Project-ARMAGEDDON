###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: security
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

output "ec2_sg_id" {
  value       = aws_security_group.ec2_sg.id
  description = "ID of the EC2 security group"
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

output "vpce_endpoints_sg_id" {
  description = "Security group ID attached to VPC Interface Endpoints"
  value       = aws_security_group.vpce_endpoints_sg.id
}

output "alb_sg_id" {
  description = "ALB security group id"
  value       = aws_security_group.alb_sg.id
}
