locals {
  region_name  = "shinjuku"
  common_tags = {
    Project     = "Chewbacca-Medical"
    Environment = "Lab3A"
    Region      = "tokyo"
    Owner       = "Student"
  }
}

# DATA SOURCES - Reference EXISTING infrastructure
data "aws_vpc" "existing" {
  provider = aws.tokyo
  id = var.existing_vpc_id
}

# Data source to find MAIN route table
data "aws_route_table" "main" {
  provider = aws.tokyo
  vpc_id = data.aws_vpc.existing.id
  
  filter {
    name   = "association.main"
    values = ["true"]
  }
}

# Create Transit Gateway (Hub)
resource "aws_ec2_transit_gateway" "hub" {
  provider = aws.tokyo
  
  description                     = "Tokyo Hub Transit Gateway V2"
  amazon_side_asn                 = 64512
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  
  tags = merge(local.common_tags, {
    Name = "${local.region_name}-hub-tgw-v3"
  })
}

# Create TGW VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "tokyo_attachment" {
  provider = aws.tokyo
  
  subnet_ids         = var.existing_private_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.hub.id
  vpc_id             = data.aws_vpc.existing.id
  
  tags = merge(local.common_tags, {
    Name = "${local.region_name}-tgw-attachment1"
  })
}

# Create TGW Route Table
resource "aws_ec2_transit_gateway_route_table" "tokyo_rt" {
  provider = aws.tokyo
  
  transit_gateway_id = aws_ec2_transit_gateway.hub.id
  
  tags = merge(local.common_tags, {
    Name = "${local.region_name}-tgw-rt"
  })
}

# Associate attachment with route table
resource "aws_ec2_transit_gateway_route_table_association" "tokyo_assoc" {
  provider = aws.tokyo
  replace_existing_association   = true

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tokyo_rt.id
}

/*# Accept peering from São Paulo
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "tokyo_accepter" {
  provider = aws.tokyo
  
  transit_gateway_attachment_id = var.sao_paulo_peering_attachment_id
  
  tags = merge(local.common_tags, {
    Name = "shinjuku-peering-accepter"
  })
}*/

# Tokyo needs this:
resource "aws_route" "tokyo_to_sao_paulo" {
  provider = aws.tokyo

  route_table_id         = "rtb-095703082c49fef13"   # data.aws_route_table.main.route_table_id
  destination_cidr_block = var.sao_paulo_vpc_cidr  # "10.103.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.hub.id
}


# Add IAM module for SSM access
module "tokyo_iam" {
  source = "../modules/iam"
  
  name_prefix  = "tokyo-shinjuku"
  common_tags  = local.common_tags
}

