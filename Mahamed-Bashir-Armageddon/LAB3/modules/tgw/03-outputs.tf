output "tgw_id" { 
    value = aws_ec2_transit_gateway.this.id 
    }
output "peering_id" { 
  value = one(aws_ec2_transit_gateway_peering_attachment.request[*].id) 
}