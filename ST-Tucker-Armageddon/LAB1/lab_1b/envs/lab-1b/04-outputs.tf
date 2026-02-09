###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: environment
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  value = module.vpc.private_subnet_ids
}

output "public_route_table_id" {
  value = module.vpc.public_route_table_id
}

output "private_route_table_id" {
  value = module.vpc.private_route_table_id
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

output "rotation_lambda_name" {
  value = module.lambda_rotation.rotation_lambda_name
}

output "rotation_lambda_account_id" {
  value = module.lambda_rotation.rotation_account_id
}

output "rotation_lambda_arn" {
  description = "Rotation Lambda ARN for Secrets Manager rotation attachment."
  value       = module.lambda_rotation.rotation_lambda_arn
}

# Output for AWS Instance ID
output "ec2_instance_id" {
  description = "Provide ID of running EC2 instance."
  value       = module.ec2.ec2_id

}

output "ec2_public_ip" {
  description = "Provide Public IP of running EC2 instance."
  value       = module.ec2.ec2_public_ip
}