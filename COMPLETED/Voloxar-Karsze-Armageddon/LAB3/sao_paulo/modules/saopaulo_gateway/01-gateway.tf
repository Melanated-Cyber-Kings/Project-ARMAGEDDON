resource "aws_ec2_transit_gateway" "liberdade_tgw01" {
  provider    = aws.sao_paulo

  #region = var.region

  description = "liberdade-tgw01 (Sao Paulo spoke)"
  tags = { Name = "liberdade-tgw01" }
}

# Explanation: Liberdade accepts the corridor from Shinjuku—permissions are explicit, not assumed.
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "liberdade_accept_peer01" {
  provider     = aws.sao_paulo

  #region = var.region

  transit_gateway_attachment_id  = var.tgw_attach_id  #aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01.id
  tags = { Name = "liberdade-accept-peer01" }
}

# Explanation: Liberdade attaches to its VPC—compute can now reach Tokyo legally, through the controlled corridor.
resource "aws_ec2_transit_gateway_vpc_attachment" "liberdade_attach_sp_vpc01" {
  provider           = aws.sao_paulo
  #region = var.region

  transit_gateway_id = aws_ec2_transit_gateway.liberdade_tgw01.id
  vpc_id             = var.vpc_id
  subnet_ids         = var.private_subnet_ids   #aws_subnet.liberdade_private_subnet01.id, aws_subnet.liberdade_private_subnet02.id
  tags = { Name = "liberdade-attach-sp-vpc01"}
}


# # Explanation: Liberdade knows the way to Shinjuku—Tokyo CIDR routes go through the TGW corridor.
# resource "aws_route" "liberdade_to_tokyo_route01" {
#   provider               = aws.sao_paulo
#   #region = var.region

#   route_table_id       =  var.private_route_table_id                           #aws_route_table.liberdade_private_rt01.id
#   destination_cidr_block = var.dest_cidr_block # Tokyo VPC CIDR (students supply)
#   transit_gateway_id     = aws_ec2_transit_gateway.liberdade_tgw01.id
# }

resource "aws_route" "liberdade_to_tokyo_vpc" {
  provider               = aws.sao_paulo
  route_table_id         = var.private_route_table_id   # São Paulo private subnet RT
  destination_cidr_block = var.dest_cidr_block           # Tokyo VPC CIDR
  transit_gateway_id     = aws_ec2_transit_gateway.liberdade_tgw01.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.liberdade_attach_sp_vpc01]
}

# CRITICAL: Static TGW route to Tokyo VPC via peering (mirrors Tokyo side)
# resource "aws_ec2_transit_gateway_route" "liberdade_to_shinjuku" {
#   destination_cidr_block         = var.dest_cidr_block  # "172.17.0.0/16" - Tokyo VPC
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_peer01.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway.liberdade_tgw01.association_default_route_table_id
  
#   depends_on = [aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_peer01]
# }

# CRITICAL: Static TGW route to Tokyo VPC via peering (mirrors Tokyo side)
resource "aws_ec2_transit_gateway_route" "liberdade_to_shinjuku" {
  destination_cidr_block         = var.dest_cidr_block   # Tokyo VPC
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_peer01.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.liberdade_tgw01.association_default_route_table_id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_peer01,
    #aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01
  ]
}

# 1) Let the TGW RT learn Liberdade VPC CIDRs from the VPC attachment
#the routes need to be propagated, otherwise it just times out
# https://www.perplexity.ai/search/given-resource-aws-ec2-transit-mPoCGdQySEeJdpeB0zX8MA
# resource "aws_ec2_transit_gateway_route_table_propagation" "liberdade_from_sp_vpc" {
#   transit_gateway_route_table_id = aws_ec2_transit_gateway.liberdade_tgw01.association_default_route_table_id
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.liberdade_attach_sp_vpc01.id
# }