output "sao_paulo_vpc_cidr" {
  description = "CIDR block of São Paulo VPC"
  value       = local.vpc_cidr
}

output "sao_paulo_tgw_id" {
  description = "ID of São Paulo Transit Gateway"
  value       = aws_ec2_transit_gateway.spoke.id
}

output "sao_paulo_tgw_peering_attachment_id" {
  description = "ID of TGW Peering Attachment"
  value       = aws_ec2_transit_gateway_peering_attachment.spoke_to_hub.id
}

output "app_server_private_ips" {
  description = "Private IPs of São Paulo app servers"
  value       = module.sao_paulo_app_server[*].private_ip
}

# Add this at the end of São Paulo main.tf
output "peering_attachment_id" {
  value = aws_ec2_transit_gateway_peering_attachment.spoke_to_hub.id
}

# Should have something like:
/*output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}*/