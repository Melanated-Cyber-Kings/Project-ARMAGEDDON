output "tokyo_vpc_cidr" {
  description = "CIDR block of Tokyo VPC"
  value       = "10.0.0.0/16"  # ← HARDCODE your Tokyo VPC CIDR
}

output "tokyo_tgw_id" {
  description = "ID of Tokyo Transit Gateway"
  value       = aws_ec2_transit_gateway.hub.id
}

output "tokyo_tgw_route_table_id" {
  description = "ID of Tokyo TGW Route Table"
  value       = aws_ec2_transit_gateway_route_table.tokyo_rt.id
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = "chewbacca-mysql.cp4248amufw3.ap-northeast-1.rds.amazonaws.com"  # ← HARDCODE
  sensitive   = true
}