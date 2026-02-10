output "ec2_sg_id" {
  value       = aws_security_group.ec2_sg.id
  description = "ID of the EC2 security group"
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

output "vpc_endpoint_sg_id" {
  description = "Security group ID for VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "alb_sg_id" {
  description = "Security group ID for VPC endpoints"
  value       = aws_security_group.alb_sg.id
}

output "rds_security_group_id" {
  description = "RDS security group ID for cross-region access"
  value       = aws_security_group.rds_sg.id
  sensitive   = false
}