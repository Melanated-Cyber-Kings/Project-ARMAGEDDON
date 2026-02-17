######################################################################################
# PHASE 1: REGIONAL FOUNDATION OUTPUTS (Inherited from Lab 1)
######################################################################################

output "vpc_id" {
  description = "The ID of the mission VPC"
  value       = module.vpc.vpc_id
}

output "ec2_instance_id" {
  description = "The ID of the private app host"
  value       = module.ec2.ec2_id
}

output "alb_dns_name" {
  description = "The direct DNS of the ALB (Use this to test ORIGIN CLOAKING)"
  value       = module.alb.alb_dns_name
}

output "rds_endpoint" {
  description = "The internal connection string for the database"
  value       = module.rds.rds_endpoint
}

######################################################################################
# PHASE 2: GLOBAL EDGE OUTPUTS (New for Lab 2A)
######################################################################################

output "cloudfront_url" {
  description = "The final authorized URL. Users should enter this in their browser."
  value       = "https://${var.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution (Required for invalidations)"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  description = "The AWS-assigned domain (e.g., d123.cloudfront.net)"
  value       = module.cloudfront.distribution_domain_name
}

output "waf_web_acl_arn" {
  description = "The ARN of the global edge shield"
  value       = module.waf.web_acl_arn
}

######################################################################################
# PHASE 3: THE RITUAL COORDINATES (Action Required)
######################################################################################

output "hosted_zone_name_servers" {
  description = "CRITICAL: Copy these 4 servers into Cloudflare as NS records for the 'lab2' subdomain."
  value       = module.dns.hosted_zone_name_servers
}

output "origin_handshake_secret" {
  description = "The 32-character secret injected into headers. Proof of 'Secret Handshake'."
  value       = local.header_value
  sensitive   = true 
}

output "tgw_id"       { 
  value = module.tgw_hub.tgw_id 
  }
output "peering_id"   { 
  value = module.tgw_hub.peering_id 
  }
output "vpc_cidr"     { 
  value = var.vpc_cidr_block 
  }