# --------------------------------------------------------
# VPC ENDPOINTS
# --------------------------------------------------------

# 1. SSM
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids = module.vpc.private_app_subnet_ids
  security_group_ids  = [module.security.vpce_sg_id] 
  private_dns_enabled = true
}

# 2. EC2Messages
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids = module.vpc.private_app_subnet_ids
  security_group_ids  = [module.security.vpce_sg_id]
  private_dns_enabled = true
}

# 3. SSMMessages
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids = module.vpc.private_app_subnet_ids
  security_group_ids  = [module.security.vpce_sg_id]
  private_dns_enabled = true
}

# 4. S3 Gateway
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [module.vpc.public_route_table_id, module.vpc.private_route_table_id]
}

# 5. Secrets Manager
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids = module.vpc.private_app_subnet_ids
  security_group_ids  = [module.security.vpce_sg_id]
  private_dns_enabled = true
}

# 6. CloudWatch Logs
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids = module.vpc.private_app_subnet_ids
  security_group_ids  = [module.security.vpce_sg_id]
  private_dns_enabled = true
}

# 7. STS
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_app_subnet_ids
  security_group_ids  = [module.security.vpce_sg_id]
  private_dns_enabled = true
}