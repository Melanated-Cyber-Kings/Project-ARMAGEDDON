###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: VPC Endpoints
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################




locals {
  interface_services = toset(concat(
    [
      "ssm",
      "ec2messages",
      "ssmmessages",
      "logs",
      "secretsmanager"
    ],
    var.enable_kms_endpoint ? ["kms"] : []
  ))
}

# Interface endpoints (SSM, Logs, Secrets Manager, optional KMS)
resource "aws_vpc_endpoint" "interface" {
  for_each            = local.interface_services
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  private_dns_enabled = true
  security_group_ids  = var.vpce_security_group_ids
  tags = {
    Name = "vpce-${each.value}"
  }
}

# S3 Gateway endpoint (classic private subnet gotcha)
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [var.private_route_table_id]

  tags = {
    Name = "vpce-s3-gateway"
  }
}
