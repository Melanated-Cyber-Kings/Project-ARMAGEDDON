# Explanation: Shinjuku Station is the hub—Tokyo is the data authority.
resource "aws_ec2_transit_gateway" "shinjuku_tgw01" {
  description = "shinjuku-tgw01 (Tokyo hub)"
  tags = { Name = "shinjuku-tgw01" }
}

# Explanation: Shinjuku connects to the Tokyo VPC—this is the gate to the medical records vault.
resource "aws_ec2_transit_gateway_vpc_attachment" "shinjuku_attach_tokyo_vpc01" {
  transit_gateway_id = aws_ec2_transit_gateway.shinjuku_tgw01.id
  vpc_id             = var.vpc_id
  subnet_ids         = var.private_subnet_ids
  tags = { Name = "shinjuku-attach-tokyo-vpc01" }
}


#enable later when sao paulo gateway is up and running

#Explanation: Shinjuku opens a corridor request to Liberdade—compute may travel, data may not.
resource "aws_ec2_transit_gateway_peering_attachment" "shinjuku_to_liberdade_peer01" {
  transit_gateway_id      = aws_ec2_transit_gateway.shinjuku_tgw01.id
  peer_region             = "sa-east-1"
  peer_transit_gateway_id = var.peer_transitgw_id # aws_ec2_transit_gateway.liberdade_tgw01.id  # created in Sao Paulo module/state
  tags = { Name = "shinjuku-to-liberdade-peer01" }
}


resource "aws_route" "shinjuku_to_sp_route01" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = var.dest_cidr_block           # Sao Paulo VPC CIDR (students supply)
  transit_gateway_id     = aws_ec2_transit_gateway.shinjuku_tgw01.id
}

# Add this: Static TGW route to remote VPC via peering (REQUIRED for cross-region)
resource "aws_ec2_transit_gateway_route" "shinjuku_to_liberdade" {
  destination_cidr_block         = var.dest_cidr_block  # Sao Paulo VPC CIDR
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.shinjuku_tgw01.association_default_route_table_id
  
  depends_on = [aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01]
}


# resource "aws_ec2_transit_gateway_route_table_association" "liberdade_attach_assoc" {
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.liberdade_attach_sp_vpc01.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway.liberdade_tgw01.association_default_route_table_id
# }

#the routes need to be propagated, otherwise it just times out
# https://www.perplexity.ai/search/given-resource-aws-ec2-transit-mPoCGdQySEeJdpeB0zX8MA
# resource "aws_ec2_transit_gateway_route_table_propagation" "shinjuku_propagate_liberdade" {
#   transit_gateway_route_table_id = aws_ec2_transit_gateway.shinjuku_tgw01.association_default_route_table_id
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01.id

#   depends_on = [aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01]
# }