output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "ec2_instance_id" {
  description = "App server ID"
  value       = module.ec2.ec2_id
}

output "alb_dns_name" {
  description = "DNS of the ALB"
  value       = module.alb.alb_dns_name
}

output "origin_handshake_secret" {
  description = "32-character secret injected into headers"
  value       = local.header_value
  sensitive   = true 
}

output "tgw_id"       { 
  value = module.tgw_spoke.tgw_id 
}

output "vpc_cidr"     { 
  value = var.vpc_cidr_block 
  }
