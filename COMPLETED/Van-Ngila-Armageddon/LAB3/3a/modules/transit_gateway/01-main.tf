resource "aws_ec2_transit_gateway" "this" {
  description = var.description
  
  # Required settings for Lab 3A
  amazon_side_asn                 = var.amazon_side_asn
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  
  # Recommended settings
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"
  
  # Optional settings (defaults shown)
  transit_gateway_cidr_blocks     = var.transit_gateway_cidr_blocks
  
  tags = merge(var.tags, {
    Name = var.name
  })
}
