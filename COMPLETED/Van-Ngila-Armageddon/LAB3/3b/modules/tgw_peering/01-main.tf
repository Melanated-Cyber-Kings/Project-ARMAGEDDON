# Request peering from requester side (Tokyo)
resource "aws_ec2_transit_gateway_peering_attachment" "requester" {
  provider = aws.requester
  
  transit_gateway_id      = var.requester_tgw_id
  peer_account_id         = var.peer_account_id
  peer_region             = var.accepter_region
  peer_transit_gateway_id = var.accepter_tgw_id
  
  tags = merge(var.tags, {
    Name = var.requester_name
    Side = "requester"
  })
}

# Accept peering from accepter side (São Paulo)
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "accepter" {
  provider = aws.accepter
  
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.requester.id
  
  tags = merge(var.tags, {
    Name = var.accepter_name
    Side = "accepter"
  })
}

# Tag the peering attachment on both sides for consistency
resource "aws_ec2_tag" "requester_tags" {
  provider = aws.requester
  
  resource_id = aws_ec2_transit_gateway_peering_attachment.requester.id
  
  for_each = merge(var.tags, {
    Name        = var.requester_name
    Side        = "requester"
    PeerRegion  = var.accepter_region
    PeerTGW     = var.accepter_tgw_id
  })
  
  key   = each.key
  value = each.value
}

resource "aws_ec2_tag" "accepter_tags" {
  provider = aws.accepter
  
  resource_id = aws_ec2_transit_gateway_peering_attachment_accepter.accepter.id
  
  for_each = merge(var.tags, {
    Name        = var.accepter_name
    Side        = "accepter"
    PeerRegion  = var.requester_region
    PeerTGW     = var.requester_tgw_id
  })
  
  key   = each.key
  value = each.value
}