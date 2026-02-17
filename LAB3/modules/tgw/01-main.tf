resource "aws_ec2_transit_gateway" "this" {
  description = "${var.name_prefix}-tgw"
  tags        = { Name = "${var.name_prefix}-tgw" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  tags               = { Name = "${var.name_prefix}-tgw-attach" }
}


# REQUESTER LOGIC (Tokyo initiates)
resource "aws_ec2_transit_gateway_peering_attachment" "request" {
  # Only activate if we are requester AND we have a Peer ID
  count = var.is_requester && var.peer_tgw_id != null ? 1 : 0

  peer_region             = var.peer_region
  peer_transit_gateway_id = var.peer_tgw_id
  transit_gateway_id      = aws_ec2_transit_gateway.this.id
  tags                    = { Name = "${var.name_prefix}-peering-request" }
}



# ACCEPTER LOGIC (Sao Paulo accepts)
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "accept" {
  count = !var.is_requester && var.peering_attachment_id != null ? 1 : 0

  transit_gateway_attachment_id = var.peering_attachment_id
  tags                          = { Name = "${var.name_prefix}-peering-accept" }
}


# --- TGW STATIC ROUTE ---
resource "aws_ec2_transit_gateway_route" "peering" {
  # Only build the route if the Attachment actually exists
  count = var.remote_cidr != null && ((var.is_requester && var.peer_tgw_id != null) || var.peering_attachment_id != null) ? 1 : 0

  destination_cidr_block         = var.remote_cidr
  transit_gateway_route_table_id = aws_ec2_transit_gateway.this.association_default_route_table_id
  
  transit_gateway_attachment_id  = var.is_requester ? aws_ec2_transit_gateway_peering_attachment.request[0].id : var.peering_attachment_id
}