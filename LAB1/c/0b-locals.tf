data "aws_region" "current" {}

# Use a list of shorthand service names
locals {
  endpoint_services = ["ssm", "ssmmessages", "ec2messages", "logs", "secretsmanager"]
}

# Dynamically look up the full service name for each
data "aws_vpc_endpoint_service" "this" {
  for_each = toset(local.endpoint_services)
  service      = each.value
  service_type = "Interface"
}

data "aws_caller_identity" "current" {}

# data "aws_kms_alias" "ssm_key" {
#   name = "alias/aws/ssm"
# }

# output "kms_arn" {
#   value = aws_kms_key.my_key.arn
# }












