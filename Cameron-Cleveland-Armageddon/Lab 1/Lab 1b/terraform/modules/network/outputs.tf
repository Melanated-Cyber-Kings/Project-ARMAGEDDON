output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}
output "public_subnet_2_id" {
  value = aws_subnet.public_2.id
}

output "private_subnet_ids" {
  value = [
    aws_subnet.private_1c.id,
    aws_subnet.private_1d.id
  ]
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}

output "database_security_group_id" {
  value = aws_security_group.database.id
}