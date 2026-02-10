output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public_a.id
}

output "public_subnet2_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public_b.id
}


output "public_subnet_ids" {
  description = "ID of the private subnets together"
  value = [aws_subnet.public_a.id,aws_subnet.public_b.id]
}


output "private_subnet_id" {
  description = "ID of the main private subnet"
  value       = aws_subnet.private_a.id
}

output "private_subnet2_id" {
  description = "ID of the other private subnet"
  value       = aws_subnet.private_b.id
}

output "private_subnet_ids" {
  description = "ID of the private subnets together"
  value = [aws_subnet.private_a.id,aws_subnet.private_b.id]
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
