
# VPC Endpoint Security Group
resource "aws_security_group" "vpc_endpoints" {
  name        = "vpc-endpoints-sg"
  description = "Security group for all VPC Interface Endpoints"
  vpc_id      = aws_vpc.lab1_vpc01.id # Replace with your VPC ID

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2_sg01.id]
  }
}

# Create Interface Endpoints
# Reference the results in your endpoint resource
resource "aws_vpc_endpoint" "ssm_endpoints" {
  for_each = data.aws_vpc_endpoint_service.this

  vpc_id              = aws_vpc.lab1_vpc01.id
  service_name        = each.value.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids         = aws_subnet.private_subnets[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]   
  

  tags = {
    Name = "${local.name_prefix}-vpce-${each.key}"
  }
}

# Commented out due to now using a Golden AMI to avoid the need to S3 access to dependacies for app downloads in 
# user_data scripts from the internet via NAT Gateway or S3 bucket.
# Add this Gateway Endpoint to your configuration
# resource "aws_vpc_endpoint" "s3_gateway" {
#   vpc_id            = aws_vpc.lab1_vpc01.id
#   service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
#   vpc_endpoint_type = "Gateway"
#   route_table_ids   = [aws_route_table.private_rt01.id] # Replace with your route table ID
  

#   tags = { Name = "s3-gateway-endpoint" }
# }
