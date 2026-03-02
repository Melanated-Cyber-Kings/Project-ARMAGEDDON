#a wee bit of vibe coding from https://www.perplexity.ai/search/how-do-this-in-terraform-use-v-dmZayjU1TxWnv82LWJsp5A

# SSM
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = var.private_subnet_ids
  security_group_ids = var.security_group_ids


  tags = {
    Name = "${var.env_prefix}-vpc-end-ssm"
  }
}

# EC2Messages
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = var.private_subnet_ids
  security_group_ids = var.security_group_ids

  tags = {
    Name = "${var.env_prefix}-vpc-end-ec2_messages"
  }
}

# SSMMessages (Session Manager)
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = var.private_subnet_ids
  security_group_ids = var.security_group_ids

  tags = {
    Name = "${var.env_prefix}-vpc-end-ssm_messages"
  }
}

# CloudWatch Logs
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = var.private_subnet_ids
  security_group_ids = var.security_group_ids

  tags = {
    Name = "${var.env_prefix}-vpc-end-logs"
  }
}

# Secrets Manager
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = var.private_subnet_ids
  security_group_ids = compact(concat(var.security_group_ids, [var.secrets_lambda_sg_id]))

  tags = {
    Name = "${var.env_prefix}-vpc-end-secretsmanager"
  }
}

# KMS (optional but common)
resource "aws_vpc_endpoint" "kms" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.kms"
  vpc_endpoint_type = "Interface"

  # KMS does not support Private DNS; omit private_dns_enabled
  subnet_ids         = var.private_subnet_ids
  security_group_ids = var.security_group_ids

  tags = {
    Name = "${var.env_prefix}-vpc-end-kms"
  }
}


resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [var.private_route_table_id]

}