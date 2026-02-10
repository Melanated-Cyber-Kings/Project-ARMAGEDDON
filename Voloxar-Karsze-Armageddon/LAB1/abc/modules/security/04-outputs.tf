output "ec2_sg_id" {
  value       = aws_security_group.ec2_sg.id
  description = "ID of the EC2 security group"
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
  description = "ID of the RDS security group"
}


output "vpc_end_sg_id" {
  value       = aws_security_group.vpc_endpoint_sg.id
  description = "ID of the VPC Endpoint security group"
}

output "alb_sg_id" {
  value       = aws_security_group.alb_sg01.id
  description = "ID of the ALB security group"
}