output "ec2_sg_id" {
  description = "ID of EC2 Security Group"
  value       = aws_security_group.ec2.id
}

output "rds_sg_id" {
  description = "ID of RDS Security Group"
  value       = aws_security_group.rds.id
}