# Sao Paulo - Lab 3A Deployment
# SEPARATE Terraform state from Tokyo
# STATELESS compute only - NO RDS, NO CloudFront, NO WAF

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Primary provider for Sao Paulo
provider "aws" {
  region = "sa-east-1"
  
  # Use same settings as Tokyo
  profile = var.aws_profile
  
  default_tags {
    tags = local.common_tags
  }
}

# Alias provider for reading Tokyo resources
provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1"
  
  profile = var.aws_profile
  
  default_tags {
    tags = local.common_tags
  }
}

# Get current account ID (from Tokyo region)
data "aws_caller_identity" "current" {
  provider = aws.tokyo
}

# Data source to read Tokyo TGW
data "aws_ec2_transit_gateway" "tokyo_tgw" {
  provider = aws.tokyo
  
  filter {
    name   = "tag:Name"
    values = ["shinjuku-tgw01"]
  }
}

# Data source to read Tokyo VPC
data "aws_vpc" "tokyo_vpc" {
  provider = aws.tokyo
  
  filter {
    name   = "tag:Name"
    values = ["armageddon-lab-1c-vpc"]  # Your Tokyo VPC tag
  }
}

# Data source to read Tokyo RDS Security Group
data "aws_security_group" "tokyo_rds_sg" {
  provider = aws.tokyo
  
  filter {
    name   = "tag:Name"
    values = ["armageddon-lab-1c-rds-sg"]  # Your RDS SG tag
  }
}

# ==================== MINIMAL VPC FOR Sao PAULO ====================

resource "aws_vpc" "liberdade_vpc" {
  cidr_block           = var.saopaulo_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

# Public Subnets
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.liberdade_vpc.id
  cidr_block        = var.public_subnet_cidr_1
  availability_zone = "sa-east-1a"
  map_public_ip_on_launch = true
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-subnet-1a"
  })
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.liberdade_vpc.id
  cidr_block        = var.public_subnet_cidr_2
  availability_zone = "sa-east-1b"
  map_public_ip_on_launch = true
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-subnet-1b"
  })
}

# Private Subnets (for EC2 instances)
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.liberdade_vpc.id
  cidr_block        = var.private_subnet_cidr_1
  availability_zone = "sa-east-1a"
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-subnet-1a"
  })
}

resource "aws_subnet" "private_1b" {
  vpc_id            = aws_vpc.liberdade_vpc.id
  cidr_block        = var.private_subnet_cidr_2
  availability_zone = "sa-east-1b"
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-subnet-1b"
  })
}

resource "aws_subnet" "private_1c" {
  vpc_id            = aws_vpc.liberdade_vpc.id
  cidr_block        = var.private_subnet_cidr_3
  availability_zone = "sa-east-1c"
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-subnet-1c"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "liberdade_igw" {
  vpc_id = aws_vpc.liberdade_vpc.id
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# NAT Gateway (single for cost optimization)
resource "aws_eip" "liberdade_nat_eip" {
  domain = "vpc"
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-eip"
  })
}

resource "aws_nat_gateway" "liberdade_nat" {
  allocation_id = aws_eip.liberdade_nat_eip.id
  subnet_id     = aws_subnet.public_a.id
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-gw"
  })
  
  depends_on = [aws_internet_gateway.liberdade_igw]
}

# Route Tables
resource "aws_route_table" "liberdade_public" {
  vpc_id = aws_vpc.liberdade_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.liberdade_igw.id
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rtb"
  })
}

resource "aws_route_table" "liberdade_private_1a" {
  vpc_id = aws_vpc.liberdade_vpc.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.liberdade_nat.id
  }
  
  route {
    cidr_block         = "172.17.0.0/16"  # São Paulo VPC CIDR
    transit_gateway_id = module.liberdade_tgw.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-rtb-1a"
  })
}

resource "aws_route_table" "liberdade_private_1b" {
  vpc_id = aws_vpc.liberdade_vpc.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.liberdade_nat.id
  }
  
  route {
    cidr_block         = "172.17.0.0/16"  # São Paulo VPC CIDR
    transit_gateway_id = module.liberdade_tgw.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-rtb-1b"
  })
}

resource "aws_route_table" "liberdade_private_1c" {
  vpc_id = aws_vpc.liberdade_vpc.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.liberdade_nat.id
  }
  
  route {
    cidr_block         = "172.17.0.0/16"  # São Paulo VPC CIDR
    transit_gateway_id = module.liberdade_tgw.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-rtb-1c"
  })
}

# Route Table Associations
resource "aws_route_table_association" "liberdade_public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.liberdade_public.id
}

resource "aws_route_table_association" "liberdade_public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.liberdade_public.id
}

resource "aws_route_table_association" "liberdade_private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.liberdade_private_1a.id
}

resource "aws_route_table_association" "liberdade_private_1b" {
  subnet_id      = aws_subnet.private_1b.id
  route_table_id = aws_route_table.liberdade_private_1b.id
}

resource "aws_route_table_association" "liberdade_private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.liberdade_private_1c.id
}

# ==================== BASIC SECURITY GROUP FOR Sao PAULO EC2 ====================

resource "aws_security_group" "liberdade_ec2_sg" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "Security group for Sao Paulo EC2 instances"
  vpc_id      = aws_vpc.liberdade_vpc.id
  
  # Allow SSH from anywhere (for lab purposes)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }
  
  # Allow HTTP (for potential ALB if added later)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }
  
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-sg"
  })
}

# ==================== IAM FOR Sao PAULO EC2 ====================

# Get Tokyo account ID (same account, different region)
data "aws_caller_identity" "tokyo_account" {
  provider = aws.tokyo
}

# IAM Role for Sao Paulo EC2
resource "aws_iam_role" "liberdade_ec2_role" {
  name = "${local.name_prefix}-ec2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-role"
  })
}

# Policy to read Tokyo SSM Parameter Store (CROSS-REGION)
resource "aws_iam_policy" "liberdade_read_tokyo_ssm" {
  name        = "${local.name_prefix}-read-tokyo-ssm"
  description = "Allow Sao Paulo EC2 to read Tokyo SSM parameters"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadTokyoSSMParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:ap-northeast-1:${data.aws_caller_identity.tokyo_account.account_id}:parameter/lab/db/*",
          "arn:aws:ssm:ap-northeast-1:${data.aws_caller_identity.tokyo_account.account_id}:parameter/lab/*"
        ]
      }
    ]
  })
  
  tags = local.common_tags
}

# Policy to read Tokyo Secrets Manager (CROSS-REGION)
resource "aws_iam_policy" "liberdade_read_tokyo_secrets" {
  name        = "${local.name_prefix}-read-tokyo-secrets"
  description = "Allow Sao Paulo EC2 to read Tokyo Secrets Manager"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadTokyoSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.tokyo_account.account_id}:secret:lab-1c/rds/mysql*",
          "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.tokyo_account.account_id}:secret:lab*/rds/*"
        ]
      },
      {
        Sid    = "ListTokyoSecrets"
        Effect = "Allow"
        Action = "secretsmanager:ListSecrets"
        Resource = "*"
      }
    ]
  })
  
  tags = local.common_tags
}

# Policy for CloudWatch Logs (Sao Paulo region)
resource "aws_iam_policy" "liberdade_cloudwatch_logs" {
  name        = "${local.name_prefix}-cloudwatch-logs"
  description = "Allow Sao Paulo EC2 to write CloudWatch logs"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:sa-east-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/${local.name_prefix}-app:*"
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "liberdade_ssm_attach" {
  role       = aws_iam_role.liberdade_ec2_role.name
  policy_arn = aws_iam_policy.liberdade_read_tokyo_ssm.arn
}

resource "aws_iam_role_policy_attachment" "liberdade_secrets_attach" {
  role       = aws_iam_role.liberdade_ec2_role.name
  policy_arn = aws_iam_policy.liberdade_read_tokyo_secrets.arn
}

resource "aws_iam_role_policy_attachment" "liberdade_cw_logs_attach" {
  role       = aws_iam_role.liberdade_ec2_role.name
  policy_arn = aws_iam_policy.liberdade_cloudwatch_logs.arn
}

# SSM Session Manager policies (required for EC2 management)
resource "aws_iam_role_policy_attachment" "liberdade_ssm_core" {
  role       = aws_iam_role.liberdade_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "liberdade_ssm_ec2" {
  role       = aws_iam_role.liberdade_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# Create instance profile
resource "aws_iam_instance_profile" "liberdade_ec2_profile" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.liberdade_ec2_role.name
  
  tags = local.common_tags
}

# ==================== Sao PAULO EC2 INSTANCE ====================

# Get latest Amazon Linux 2 AMI for Sao Paulo
data "aws_ami" "amazon_linux_2_saopaulo" {
  most_recent = true
  owners      = ["amazon"]
  
  # filter {
  #   name   = "name"
  #   values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  # }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance (Stateless app server)
resource "aws_instance" "liberdade_ec2" {
  ami           = "ami-08dd439af9c3f1639" # var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2_saopaulo.id
  instance_type = "t3.micro"              # var.instance_type
  subnet_id     = aws_subnet.private_1a.id  # Use first private subnet
  
  # Security groups
  vpc_security_group_ids = [aws_security_group.liberdade_ec2_sg.id]
  
  # IAM instance profile
  iam_instance_profile = aws_iam_instance_profile.liberdade_ec2_profile.name
  
  # User data - application setup
  user_data_base64 = base64encode(local.user_data)
  
  # Root volume
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }
  
  # Enable termination protection
  disable_api_termination = false  # Set to true in production
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-app"
    Role = "stateless-app"
    RDS  = "tokyo"  # Indicates this connects to Tokyo RDS
  })
  
  # Required for SSM Session Manager
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

# ==================== VPC ENDPOINTS FOR Sao PAULO ====================
# Required for cross-region access to AWS services

# Security group for VPC endpoints
resource "aws_security_group" "liberdade_vpc_endpoints_sg" {
  name        = "${local.name_prefix}-vpc-endpoints-sg"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = aws_vpc.liberdade_vpc.id
  
  # Allow HTTPS from EC2 instances
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.liberdade_vpc.cidr_block]
    description = "HTTPS from EC2 instances"
  }
  
  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc-endpoints-sg"
  })
}

# SSM VPC Endpoint (REQUIRED for cross-region SSM access)
resource "aws_vpc_endpoint" "liberdade_ssm" {
  vpc_id              = aws_vpc.liberdade_vpc.id
  service_name        = "com.amazonaws.sa-east-1.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  
  subnet_ids          = [aws_subnet.private_1a.id, aws_subnet.private_1b.id]
  security_group_ids  = [aws_security_group.liberdade_vpc_endpoints_sg.id]
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ssm-endpoint"
  })
}

# SSM Messages Endpoint (for Session Manager)
resource "aws_vpc_endpoint" "liberdade_ssmmessages" {
  vpc_id              = aws_vpc.liberdade_vpc.id
  service_name        = "com.amazonaws.sa-east-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  
  subnet_ids          = [aws_subnet.private_1a.id, aws_subnet.private_1b.id]
  security_group_ids  = [aws_security_group.liberdade_vpc_endpoints_sg.id]
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ssmmessages-endpoint"
  })
}

# EC2 Messages Endpoint (for Session Manager)
resource "aws_vpc_endpoint" "liberdade_ec2messages" {
  vpc_id              = aws_vpc.liberdade_vpc.id
  service_name        = "com.amazonaws.sa-east-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  
  subnet_ids          = [aws_subnet.private_1a.id, aws_subnet.private_1b.id]
  security_group_ids  = [aws_security_group.liberdade_vpc_endpoints_sg.id]
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2messages-endpoint"
  })
}

# Secrets Manager VPC Endpoint (for cross-region secrets access)
resource "aws_vpc_endpoint" "liberdade_secretsmanager" {
  vpc_id              = aws_vpc.liberdade_vpc.id
  service_name        = "com.amazonaws.sa-east-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  
  subnet_ids          = [aws_subnet.private_1a.id, aws_subnet.private_1b.id]
  security_group_ids  = [aws_security_group.liberdade_vpc_endpoints_sg.id]
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-secretsmanager-endpoint"
  })
}

# ==================== Sao PAULO TRANSIT GATEWAY ====================

module "liberdade_tgw" {
  source = "../../modules/transit_gateway"
  
  name        = "liberdade-tgw01"
  description = "Sao Paulo Transit Gateway spoke (Liberdade)"
  region      = "sa-east-1"
  
  amazon_side_asn = 64513  # Different ASN from Tokyo
  
  tags = merge(local.common_tags, {
    Component = "transit-gateway"
    Role      = "spoke"
  })
}

# Attach Sao Paulo VPC to TGW
module "liberdade_tgw_attachment" {
  source = "../../modules/tgw_attachment"
  
  name              = "liberdade-attach-sp-vpc01"
  region            = "sa-east-1"
  transit_gateway_id = module.liberdade_tgw.id
  vpc_id            = aws_vpc.liberdade_vpc.id
  subnet_ids        = [aws_subnet.private_1a.id, aws_subnet.private_1b.id]
  
  tags = merge(local.common_tags, {
    Component = "tgw-attachment"
    VPC       = aws_vpc.liberdade_vpc.id
  })
}

# ==================== TGW PEERING ====================

module "tokyo_saopaulo_peering" {
  source = "../../modules/tgw_peering"
  
  providers = {
    aws.requester = aws.tokyo    # Tokyo side initiates
    aws.accepter  = aws          # Sao Paulo side accepts
  }
  
  # Tokyo side (requester)
  requester_name        = "shinjuku-to-liberdade-peer01"
  requester_tgw_id      = local.tokyo_tgw_id
  requester_region      = "ap-northeast-1"
  
  # Sao Paulo side (accepter)  
  accepter_name         = "liberdade-accept-peer01"
  accepter_tgw_id       = module.liberdade_tgw.id
  accepter_region       = "sa-east-1"
  
  peer_account_id       = data.aws_caller_identity.current.account_id
  
  tags = merge(local.common_tags, {
    Component    = "tgw-peering"
    CrossRegion  = "true"
    Connection   = "tokyo-saopaulo"
  })
}

# ==================== ROUTING ====================

# Route from Sao Paulo to Tokyo VPC via TGW
resource "aws_route" "liberdade_to_tokyo" {
  count = length([aws_route_table.liberdade_private_1a.id, 
                  aws_route_table.liberdade_private_1b.id,
                  aws_route_table.liberdade_private_1c.id])
  
  route_table_id         = [aws_route_table.liberdade_private_1a.id, 
                           aws_route_table.liberdade_private_1b.id,
                           aws_route_table.liberdade_private_1c.id][count.index]
  destination_cidr_block = local.tokyo_vpc_cidr  # Tokyo VPC CIDR
  transit_gateway_id     = module.liberdade_tgw.id
  
  # Wait for peering to be established
  depends_on = [module.tokyo_saopaulo_peering]
}

# resource "aws_ec2_transit_gateway_route_table_propagation" "saopaulo_from_peering" {
#   # Get São Paulo TGW route table ID from module output
#   transit_gateway_route_table_id = module.liberdade_tgw.transit_gateway_route_table_id
  
#   # Get peering attachment ID from module output  
#   transit_gateway_attachment_id  = module.tokyo_saopaulo_peering.peering_attachment_id
# }

# resource "aws_ec2_transit_gateway_route_table_propagation" "saopaulo_from_vpc" {
#   transit_gateway_route_table_id = module.liberdade_tgw.transit_gateway_route_table_id
#   transit_gateway_attachment_id  = module.liberdade_tgw_attachment.transit_gateway_attachment_id
# }

resource "aws_ec2_transit_gateway_route" "saopaulo_to_tokyo" {
  destination_cidr_block         = "172.17.0.0/16"
  transit_gateway_route_table_id = module.liberdade_tgw.transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tokyo_saopaulo_peering.peering_attachment_id
}