output "vpc_id" {
  value = module.vpc.vpc_id
}

# output "public_subnet_id" {
#   value = module.vpc.public_subnet_id
# }

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

# output "public_route_table_id" {
#   value = module.vpc.public_route_table_id
# }

output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}

output "iam_role_name" {
  value = module.iam.role_name
}

output "iam_instance_profile_name" {
  value = module.iam.instance_profile_name
}

# output "port" {
#   value = module.rds.port
# }

output "address" {
  value = module.rds.address
}

# output "ec2_instance_id_bonus" {
#   value = module.ec2.ec2_instance_id_bonus
# }

output "name_servers" {
  value = module.dns.name_servers
}

output "website_url" {
  value = "https://${var.app_subdomain}.${var.domain_name}"
}

# Bonus D outputs
output "alb_logs_bucket_name" {
  value = module.s3_logs.alb_logs_bucket_name
}

output "alb_logs_bucket_arn" {
  value = module.s3_logs.alb_logs_bucket_arn
}

output "apex_url_https" {
  value = module.dns.apex_url_https
}

output "alb_access_logs_enabled" {
  value = var.enable_alb_access_logs
}