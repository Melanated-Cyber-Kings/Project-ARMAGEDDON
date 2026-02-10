output "id" {
  description = "TGW VPC Attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.id
}

output "vpc_id" {
  description = "Attached VPC ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.vpc_id
}

output "subnet_ids" {
  description = "Attached subnet IDs"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.subnet_ids
}

output "transit_gateway_attachment_id" {
  description = "The ID of the Transit Gateway VPC Attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.id
}