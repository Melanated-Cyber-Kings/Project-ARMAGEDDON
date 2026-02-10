output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.availability_zones
}

# Legacy outputs for backward compatibility
output "public_subnet_id" {
  description = "First public subnet ID (legacy)"
  value       = length(aws_subnet.public) > 0 ? aws_subnet.public[0].id : ""
}

output "private_subnet_id" {
  description = "First private subnet ID (legacy)"
  value       = length(aws_subnet.private) > 0 ? aws_subnet.private[0].id : ""
}

output "avail_zone" {
  description = "First availability zone (legacy)"
  value       = length(local.availability_zones) > 0 ? local.availability_zones[0] : ""
}

output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Private route table ID"
  value       = aws_route_table.private.id
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.this.name
}
