# Tokyo Routes for São Paulo VPC
resource "aws_route" "tokyo_to_saopaulo" {
  count = length(module.vpc.private_route_table_ids)
  
  route_table_id         = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = var.saopaulo_vpc_cidr  # "172.18.0.0/16"
  transit_gateway_id     = module.shinjuku_tgw.id
  
  # Wait for TGW and attachment to be ready
  depends_on = [
    module.shinjuku_tgw,
    module.shinjuku_tgw_attachment
  ]
  
  # Add description for clarity
  # Note: description field not available for aws_route
}

# Add tags through a null_resource since aws_route doesn't support tags directly
# resource "aws_ec2_tag" "tokyo_route_tags" {
#   count = length(module.vpc.private_route_table_ids)
  
#   resource_id = aws_route.tokyo_to_saopaulo[count.index].route_table_id
  
#   key   = "Lab3A-Route"
#   value = "to-saopaulo-via-tgw"
# }
data "aws_ec2_transit_gateway_peering_attachment" "tokyo_saopaulo" {
  filter {
    name   = "transit-gateway-attachment-id"
    values = ["tgw-attach-041d5b46c2379aaf5"]  # The peering attachment ID
  }
}

resource "aws_ec2_transit_gateway_route" "tokyo_to_saopaulo" {
  destination_cidr_block         = "172.18.0.0/16"
  transit_gateway_route_table_id = module.shinjuku_tgw.transit_gateway_route_table_id
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_peering_attachment.tokyo_saopaulo.id
}