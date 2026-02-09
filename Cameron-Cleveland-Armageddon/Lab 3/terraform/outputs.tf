output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = values(aws_subnet.private)[*].id
}
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = values(aws_subnet.public)[*].id
}
