locals {
  region_name  = "liberdade"
  vpc_cidr    = "10.103.0.0/16"
  common_tags = {
    Project     = "Chewbacca-Medical"
    Environment = "Lab3A"
    Region      = "sao-paulo"
    Owner       = "Student"
  }
}

# Create VPC using module - NO PRIVATE SUBNETS
module "sao_paulo_vpc" {
  source = "../modules/vpc"

  region_name  = local.region_name
  vpc_cidr    = local.vpc_cidr
  availability_zones = ["sa-east-1a", "sa-east-1c"]

  public_subnet_cidrs = {
    public1 = "10.103.1.0/24"
    public2 = "10.103.2.0/24"
  }

  # No private_subnet_cidrs defined - this is a compute-only region
  common_tags = local.common_tags
}

# Create Transit Gateway (Spoke)
resource "aws_ec2_transit_gateway" "spoke" {
  provider = aws.sao_paulo

  description                     = "Sao Paulo Spoke Transit Gateway"
  amazon_side_asn                 = 64513
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = merge(local.common_tags, {
    Name = "${local.region_name}-spoke-tgw1"
  })
}

# Create TGW VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "sao_paulo_attachment" {
  provider = aws.sao_paulo

  subnet_ids         = module.sao_paulo_vpc.public_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.spoke.id
  vpc_id             = module.sao_paulo_vpc.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.region_name}-tgw-attachment1"
  })
}

# Create TGW Route Table
resource "aws_ec2_transit_gateway_route_table" "sao_paulo_rt" {
  provider = aws.sao_paulo

  transit_gateway_id = aws_ec2_transit_gateway.spoke.id

  tags = merge(local.common_tags, {
    Name = "${local.region_name}-tgw-rt"
  })
}

# Associate TGW attachment with route table
/*resource "aws_ec2_transit_gateway_route_table_association" "sao_paulo_assoc" {
  provider = aws.sao_paulo
  
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.sao_paulo_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.sao_paulo_rt.id
}*/

# Create TGW Peering Attachment - São Paulo initiates
resource "aws_ec2_transit_gateway_peering_attachment" "spoke_to_hub" {
  provider = aws.sao_paulo

  peer_account_id         = data.aws_caller_identity.current.account_id
  peer_region             = "ap-northeast-1"
  peer_transit_gateway_id = var.tokyo_tgw_id
  transit_gateway_id      = aws_ec2_transit_gateway.spoke.id

  tags = merge(local.common_tags, {
    Name = "${local.region_name}-to-shinjuku-peering1"
  })
}

# Create route in São Paulo TGW route table to Tokyo
resource "aws_ec2_transit_gateway_route" "to_tokyo" {
  provider = aws.sao_paulo

  destination_cidr_block         = var.tokyo_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.spoke_to_hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.sao_paulo_rt.id
  
  depends_on = [aws_ec2_transit_gateway_peering_attachment.spoke_to_hub]
}

# Add this data source to find existing route tables
data "aws_route_tables" "sao_paulo" {
  provider = aws.sao_paulo
  vpc_id = module.sao_paulo_vpc.vpc_id
}

# São Paulo needs this:
resource "aws_route" "sao_paulo_to_tokyo" {
  provider = aws.sao_paulo
  route_table_id = data.aws_route_tables.sao_paulo.ids[0]
  destination_cidr_block = var.tokyo_vpc_cidr  # Tokyo's VPC CIDR
  transit_gateway_id     = aws_ec2_transit_gateway.spoke.id
}

# Add IAM module for SSM
module "sao_paulo_iam" {
  source = "../modules/iam"

  name_prefix  = "sp-liberdade"
  common_tags  = local.common_tags
}

# Create App Servers
module "sao_paulo_app_server" {
  source = "../modules/app_server"

  name_prefix    = local.region_name
  vpc_id        = module.sao_paulo_vpc.vpc_id
  subnet_id     = module.sao_paulo_vpc.public_subnet_ids[0]
  instance_type = "t3.micro"
  iam_instance_profile = module.sao_paulo_iam.instance_profile_name

  # Database connection info for Flask app
  rds_endpoint = var.rds_endpoint
  db_username  = var.db_username
  db_password  = var.db_password

  count = 1
}

data "aws_caller_identity" "current" {
  provider = aws.sao_paulo
}
