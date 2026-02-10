output "endpoint_ids" {
  description = "Map of VPC endpoint IDs by service name"
  value = {
    ssm            = try(aws_vpc_endpoint.ssm.id, "")
    ssmmessages    = try(aws_vpc_endpoint.ssm_messages.id, "")
    ec2messages    = try(aws_vpc_endpoint.ec2_messages.id, "")
    ec2_api        = try(aws_vpc_endpoint.ec2.id, "")
    secretsmanager = try(aws_vpc_endpoint.secrets_manager.id, "")
    logs           = try(aws_vpc_endpoint.logs.id, "")
    s3             = try(aws_vpc_endpoint.s3.id, "")
    kms            = try(aws_vpc_endpoint.kms[0].id, "")
  }
}

output "endpoint_dns_entries" {
  description = "DNS entries for each VPC endpoint"
  value = {
    ssm            = try(aws_vpc_endpoint.ssm.dns_entry, [])
    ssmmessages    = try(aws_vpc_endpoint.ssm_messages.dns_entry, [])
    ec2messages    = try(aws_vpc_endpoint.ec2_messages.dns_entry, [])
    ec2_api        = try(aws_vpc_endpoint.ec2.dns_entry, [])
    secretsmanager = try(aws_vpc_endpoint.secrets_manager.dns_entry, [])
    logs           = try(aws_vpc_endpoint.logs.dns_entry, [])
    s3             = try(aws_vpc_endpoint.s3.dns_entry, [])
    kms            = try(aws_vpc_endpoint.kms[0].dns_entry, [])
  }
}

output "endpoint_service_names" {
  description = "Service names of created endpoints"
  value = {
    ssm            = try(aws_vpc_endpoint.ssm.service_name, "")
    ssmmessages    = try(aws_vpc_endpoint.ssm_messages.service_name, "")
    ec2messages    = try(aws_vpc_endpoint.ec2_messages.service_name, "")
    ec2_api        = try(aws_vpc_endpoint.ec2.service_name, "")
    secretsmanager = try(aws_vpc_endpoint.secrets_manager.service_name, "")
    logs           = try(aws_vpc_endpoint.logs.service_name, "")
    s3             = try(aws_vpc_endpoint.s3.service_name, "")
    kms            = try(aws_vpc_endpoint.kms[0].service_name, "")
  }
}

output "endpoint_arns" {
  description = "ARNs of created VPC endpoints"
  value = {
    ssm            = try(aws_vpc_endpoint.ssm.arn, "")
    ssmmessages    = try(aws_vpc_endpoint.ssm_messages.arn, "")
    ec2messages    = try(aws_vpc_endpoint.ec2_messages.arn, "")
    ec2_api        = try(aws_vpc_endpoint.ec2.arn, "")
    secretsmanager = try(aws_vpc_endpoint.secrets_manager.arn, "")
    logs           = try(aws_vpc_endpoint.logs.arn, "")
    s3             = try(aws_vpc_endpoint.s3.arn, "")
    kms            = try(aws_vpc_endpoint.kms[0].arn, "")
  }
}

output "s3_endpoint_prefix_list_id" {
  description = "Prefix list ID of the S3 gateway endpoint"
  value       = try(aws_vpc_endpoint.s3.prefix_list_id, "")
}

output "interface_endpoint_security_group_id" {
  description = "Security group ID used for interface endpoints"
  value       = var.vpc_endpoint_sg_id
}

output "all_endpoint_ids_list" {
  description = "List of all VPC endpoint IDs"
  value = compact([
    try(aws_vpc_endpoint.ssm.id, null),
    try(aws_vpc_endpoint.ssm_messages.id, null),
    try(aws_vpc_endpoint.ec2_messages.id, null),
    try(aws_vpc_endpoint.secrets_manager.id, null),
    try(aws_vpc_endpoint.logs.id, null),
    try(aws_vpc_endpoint.s3.id, null),
    try(aws_vpc_endpoint.kms[0].id, null),
    try(aws_vpc_endpoint.ec2.id, [])
  ])
}

output "endpoint_count" {
  description = "Number of VPC endpoints created"
  value = length(compact([
    try(aws_vpc_endpoint.ssm.id, null),
    try(aws_vpc_endpoint.ssm_messages.id, null),
    try(aws_vpc_endpoint.ec2_messages.id, null),
    try(aws_vpc_endpoint.secrets_manager.id, null),
    try(aws_vpc_endpoint.logs.id, null),
    try(aws_vpc_endpoint.s3.id, null),
    try(aws_vpc_endpoint.kms[0].id, null),
    try(aws_vpc_endpoint.ec2.id, [])
  ]))
}

# Nouveaux outputs utiles
output "s3_endpoint_route_table_ids" {
  description = "Route table IDs associated with the S3 endpoint"
  value       = try(aws_vpc_endpoint.s3.route_table_ids, [])
}

output "interface_endpoint_subnet_ids" {
  description = "Subnet IDs used for interface endpoints"
  value       = var.private_subnet_ids
}

output "vpc_id" {
  description = "VPC ID where endpoints are created"
  value       = var.vpc_id
}

output "vpc_endpoint_sg_id" {
  value = var.vpc_endpoint_sg_id
}

# output "vpce_ssm_id" {
#   value = var.endpoint_ids.ssm
# }

# output "vpce_logs_id" {
#   value =var.endpoint_ids.logs
# }

# output "vpce_secrets_id" {
#   value = var.endpoint_ids.secretsmanager
# }

# output "vpce_s3_id" {
#   value = var.endpoint_ids.s3
# }