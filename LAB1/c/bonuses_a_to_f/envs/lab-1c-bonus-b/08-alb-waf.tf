# 1. DNS & ACM 
module "dns" {
  source       = "../../modules/dns"
  domain_name  = var.domain_name
  name_prefix  = local.name_prefix
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}

# 2. Application Load Balancer
module "alb" {
  source             = "../../modules/alb"
  name_prefix        = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_ids = [module.security.alb_sg_id]
  target_id          = module.ec2.ec2_id
  
  
  access_logs_bucket = module.s3_logs.bucket_id 
  
  
  certificate_arn    = module.dns.certificate_arn
}

# 3. WAF
module "waf" {
  source       = "../../modules/waf"
  name_prefix  = local.name_prefix
  resource_arn = module.alb.alb_arn
}