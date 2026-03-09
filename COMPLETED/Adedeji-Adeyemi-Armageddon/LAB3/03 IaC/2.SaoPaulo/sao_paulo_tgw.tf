resource "aws_ec2_transit_gateway" "liberdade_tgw01" {
  description = "liberdade-tgw01 (Sao Paulo spoke)"
  tags        = { Name = "liberdade-tgw01" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "liberdade_attach_sp_vpc01" {
  transit_gateway_id = aws_ec2_transit_gateway.liberdade_tgw01.id
  vpc_id             = aws_vpc.liberdade_vpc01.id
  subnet_ids         = [aws_subnet.liberdade_private_subnet01.id, aws_subnet.liberdade_private_subnet02.id]
  tags               = { Name = "liberdade-attach-sp-vpc01" }
}

# São Paulo reaches out to Tokyo
resource "aws_ec2_transit_gateway_peering_attachment" "liberdade_to_shinjuku_peer" {
  peer_region             = "ap-northeast-1"
  peer_transit_gateway_id = data.terraform_remote_state.tokyo.outputs.tgw_id
  transit_gateway_id      = aws_ec2_transit_gateway.liberdade_tgw01.id
  tags                    = { Name = "liberdade-to-shinjuku-peer" }
}

# Acting in Tokyo, but from this state file
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "shinjuku_accepter" {
  provider                      = aws.tokyo
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.liberdade_to_shinjuku_peer.id
  tags                          = { Name = "shinjuku-accepter-for-brazil" }
}

# 3. Tell the TGW how to find Tokyo
resource "aws_ec2_transit_gateway_route" "liberdade_to_tokyo_tgw_static" {
  destination_cidr_block         = data.terraform_remote_state.tokyo.outputs.vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.liberdade_to_shinjuku_peer.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.liberdade_tgw01.propagation_default_route_table_id

  depends_on = [aws_ec2_transit_gateway_peering_attachment_accepter.shinjuku_accepter]
}
