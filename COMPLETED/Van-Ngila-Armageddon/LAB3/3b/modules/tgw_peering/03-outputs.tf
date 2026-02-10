output "peering_attachment_id" {
  description = "TGW Peering Attachment ID"
  value       = aws_ec2_transit_gateway_peering_attachment.requester.id
}

output "state" {
  description = "Peering attachment state"
  value       = aws_ec2_transit_gateway_peering_attachment.requester.state
}

output "accepter_id" {
  description = "Accepter resource ID"
  value       = aws_ec2_transit_gateway_peering_attachment_accepter.accepter.id
}