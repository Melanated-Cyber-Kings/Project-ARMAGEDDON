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