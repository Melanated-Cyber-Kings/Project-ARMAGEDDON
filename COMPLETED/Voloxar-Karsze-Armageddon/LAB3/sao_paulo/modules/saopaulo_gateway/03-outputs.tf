output "peer_tgw_id" {
    value = aws_ec2_transit_gateway.liberdade_tgw01.id
}

output "dest_cidr_block" {
    value = var.dest_cidr_block
}

output "private_route_table_id" {
    value = var.private_route_table_id
}

output "transit_gateway_id" { #same as peer_tgw_id
    value = aws_ec2_transit_gateway.liberdade_tgw01.id
}

output "tgw_attach_id" {
    value = aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_peer01.id
}