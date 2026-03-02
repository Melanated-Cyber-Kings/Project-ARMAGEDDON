output "tgw_attach_id" {
    value = aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01.id
}

output "private_route_table_id" {
    value = var.private_route_table_id
}

output "transit_gateway_id" {
    value = aws_ec2_transit_gateway.shinjuku_tgw01.id
}

output "dest_cidr_block" {
    value = var.dest_cidr_block
}