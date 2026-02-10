
resource "aws_ec2_transit_gateway" "shinjuku_tgw01" {
  description = "shinjuku-tgw01 (Tokyo hub)"
  tags        = { Name = "shinjuku-tgw01" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "shinjuku_attach_tokyo_vpc01" {
  transit_gateway_id = aws_ec2_transit_gateway.shinjuku_tgw01.id
  vpc_id             = aws_vpc.chewbacca_vpc01.id
  subnet_ids         = [
    aws_subnet.chewbacca_private_subnet01.id,
    aws_subnet.chewbacca_private_subnet02.id
  ]
  tags = { Name = "shinjuku-attach-tokyo-vpc01" }
}

resource "aws_ec2_transit_gateway_route" "shinjuku_to_liberdade_tgw_static" {
  destination_cidr_block         = "10.102.0.0/16"
  transit_gateway_attachment_id  = data.terraform_remote_state.saopaulo.outputs.tgw_peering_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.shinjuku_tgw01.propagation_default_route_table_id
}
