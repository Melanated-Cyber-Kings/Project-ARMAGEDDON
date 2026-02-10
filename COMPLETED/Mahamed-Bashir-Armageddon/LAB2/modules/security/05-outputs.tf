output "ec2_sg_id" {
  value       = aws_security_group.ec2_sg.id
  description = "ID of the EC2 security group"
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

output "vpce_sg_id" {
  value       = aws_security_group.vpce_sg.id
  description = "ID of the VPC Endpoint security group"
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}