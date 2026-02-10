# São Paulo outputs
output "vpc_id" {
  description = "São Paulo VPC ID"
  value       = aws_vpc.liberdade_vpc.id
}

output "vpc_cidr_block" {
  description = "São Paulo VPC CIDR"
  value       = aws_vpc.liberdade_vpc.cidr_block
}

output "private_subnet_ids" {
  description = "São Paulo private subnet IDs"
  value       = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1b.id,
    aws_subnet.private_1c.id
  ]
}

output "private_route_table_ids" {
  description = "São Paulo private route table IDs"
  value       = [
    aws_route_table.liberdade_private_1a.id,
    aws_route_table.liberdade_private_1b.id,
    aws_route_table.liberdade_private_1c.id
  ]
}

output "ec2_security_group_id" {
  description = "São Paulo EC2 security group ID"
  value       = aws_security_group.liberdade_ec2_sg.id
}

output "ec2_instance_id" {
  description = "São Paulo EC2 instance ID"
  value       = aws_instance.liberdade_ec2.id
}

output "ec2_private_ip" {
  description = "São Paulo EC2 private IP"
  value       = aws_instance.liberdade_ec2.private_ip
}

output "ec2_public_ip" {
  description = "São Paulo EC2 public IP (if in public subnet)"
  value       = try(aws_instance.liberdade_ec2.public_ip, "")
}

output "iam_role_arn" {
  description = "São Paulo EC2 IAM role ARN"
  value       = aws_iam_role.liberdade_ec2_role.arn
}

output "instance_profile_name" {
  description = "São Paulo EC2 instance profile name"
  value       = aws_iam_instance_profile.liberdade_ec2_profile.name
}