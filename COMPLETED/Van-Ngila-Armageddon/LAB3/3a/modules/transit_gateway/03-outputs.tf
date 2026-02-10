output "id" {
  description = "Transit Gateway ID"
  value       = aws_ec2_transit_gateway.this.id
}

output "arn" {
  description = "Transit Gateway ARN"
  value       = aws_ec2_transit_gateway.this.arn
}

output "association_default_route_table_id" {
  description = "Identifier of the default association route table"
  value       = aws_ec2_transit_gateway.this.association_default_route_table_id
}

output "propagation_default_route_table_id" {
  description = "Identifier of the default propagation route table"
  value       = aws_ec2_transit_gateway.this.propagation_default_route_table_id
}

output "owner_id" {
  description = "AWS Account ID of the Transit Gateway owner"
  value       = aws_ec2_transit_gateway.this.owner_id
}

output "transit_gateway_route_table_id" {
  description = "The ID of the default Transit Gateway Route Table"
  value       = aws_ec2_transit_gateway.this.association_default_route_table_id
}

output "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.this.id
}
