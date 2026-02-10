output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public_a.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private_a.id
}






############################
# Public Route Table
############################
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

############################
# Private Route Table
############################
output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}


output "db_subnet_group_name" {
  value = aws_db_subnet_group.this.name
}
