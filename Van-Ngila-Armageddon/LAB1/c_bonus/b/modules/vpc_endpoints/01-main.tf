# Interface Endpoints (AWS PrivateLink)
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [var.vpc_endpoint_sg_id]
  subnet_ids         = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-ssm-endpoint"
  })
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [var.vpc_endpoint_sg_id]
  subnet_ids         = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-ssmmessages-endpoint"
  })
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [var.vpc_endpoint_sg_id]
  subnet_ids         = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-ec2messages-endpoint"
  })
}

resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [var.vpc_endpoint_sg_id]
  subnet_ids         = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-secretsmanager-endpoint"
  })
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [var.vpc_endpoint_sg_id]
  subnet_ids         = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-logs-endpoint"
  })
}

# S3 Gateway Endpoint (for package installs, CloudWatch logs, etc.)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids  

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-s3-endpoint"
  })
}

# Optional: KMS endpoint
resource "aws_vpc_endpoint" "kms" {
  count = var.enable_kms_endpoint ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.kms"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [var.vpc_endpoint_sg_id]
  subnet_ids         = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-kms-endpoint"
  })
}

# EC2 API Endpoint (nécessaire pour les commandes AWS CLI EC2)
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [var.vpc_endpoint_sg_id]
  subnet_ids         = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-ec2-api-endpoint"
  })
}