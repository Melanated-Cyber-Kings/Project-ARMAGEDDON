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

output "alb_public" {
  value = aws_lb.alb_public.id
}

output "alb_arn" {
  description = "ARN of the public ALB"
  value       = aws_lb.alb_public.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the public ALB"
  value       = aws_lb.alb_public.arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of the public ALB"
  value       = aws_lb.alb_public.dns_name
}

output "alb_zone_id" {
  description = "Route53 zone ID of the ALB"
  value       = aws_lb.alb_public.zone_id
}

output "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.alb_private_targets.arn
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = var.alb_sg_id
}