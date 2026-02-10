output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  value = module.vpc.private_subnet_id
}

output "iam_role_name" {
  value = module.iam.role_name
}

output "iam_instance_profile_name" {
  value = module.iam.instance_profile_name
}

output "public_route_table_id" {
  description = "Public route table ID"
  value       = module.vpc.public_route_table_id
}

output "private_route_table_id" {
  description = "Private route table ID"
  value       = module.vpc.private_route_table_id
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = module.vpc.db_subnet_group_name
}

# RDS Outputs - using CORRECT output names from the module
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
}

output "rds_address" {
  description = "RDS address"
  value       = module.rds.db_address
}

output "rds_instance_id" {
  description = "RDS instance ID"
  value       = module.rds.db_instance_id
}

output "rds_identifier" {
  description = "RDS identifier"
  value       = module.rds.db_identifier
}

output "rds_multi_az" {
  description = "Whether RDS is Multi-AZ"
  value       = module.rds.multi_az
}

output "rds_status" {
  description = "RDS status"
  value       = module.rds.db_status
}

output "rds_instance_class" {
  description = "RDS instance class"
  value       = module.rds.db_instance_class
}

output "rds_availability_zone" {
  description = "RDS availability zone"
  value       = module.rds.availability_zone
}
