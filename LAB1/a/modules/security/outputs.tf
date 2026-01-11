output "ec2_sg_id" {
  value       = aws_security_group.ec2_sg.id
  description = "ID of the EC2 security group"
}
