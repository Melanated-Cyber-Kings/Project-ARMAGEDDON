############################
# VPC
############################
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

############################
# Private Subnets
############################
output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = [
    aws_subnet.private_1a.id,
    aws_subnet.private_2a.id,
    aws_subnet.private_1c.id
  ]
}

############################
# Private Route Tables
############################
output "private_route_table_ids" {
  description = "List of private route table IDs"
  value = [
    aws_route_table.private_1a.id,
    aws_route_table.private_2a.id,
    aws_route_table.private_1c.id
  ]
}

############################
# DB Subnet Group
############################
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.this.name
}