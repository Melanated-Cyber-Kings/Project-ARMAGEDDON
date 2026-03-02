output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  value = module.vpc.private_subnet_id
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

#moved to domain_name_init
# output "name_servers" {
#   description = "Name servers for the hosted zone"
#   value       = module.zone53.name_servers
# }


output "certificate_arn" {
  description = "Issued ACM certificate ARN"
  value       = module.zone53.certificate_arn
}

output load_balancer_address {
  value = module.alb_waf.lb_dns_name
}

output https_url {
  value = "https://${var.app_subdomain}.${var.domain_name}"
}


output origin_handshake_secret {
  value = module.cloudfront.header_value
  sensitive = true
}
