resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  
  # Required settings
  dns_support        = "enable"
  ipv6_support       = "disable"
  
  # Optional settings
  appliance_mode_support = var.appliance_mode_support
  
  tags = merge(var.tags, {
    Name = var.name
  })
}