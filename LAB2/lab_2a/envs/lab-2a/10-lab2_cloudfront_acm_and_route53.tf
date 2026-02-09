###############################################################################
# LAB-2A: ACM (us-east-1) + Route53 aliases to CloudFront
#
# - CloudFront viewer cert MUST be in us-east-1
# - DNS validation via Route53 when enable_route53=true
###############################################################################

# Uses the same provider alias defined in 09-lab2_cloudfront_waf_and_distribution.tf
# (Do NOT re-declare provider aws.us_east_1 here)

# resource "aws_acm_certificate" "cf_cert" {
#   provider = aws.us_east_1

#   domain_name               = var.domain_name
#   #subject_alternative_names = ["${var.app_subdomain}.${var.domain_name}"]
#   subject_alternative_names = []
#   validation_method         = "DNS"

#   tags = merge(var.tags, {
#     Name = "${local.name_prefix}-cf-cert"
#   })

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# locals {
#   cf_acm_dvo = {
#     for dvo in aws_acm_certificate.cf_cert.domain_validation_options :
#     dvo.domain_name => {
#       name  = dvo.resource_record_name
#       type  = dvo.resource_record_type
#       value = dvo.resource_record_value
#     }
#   }
# }

# resource "aws_route53_record" "cf_cert_validation" {
#   for_each = var.enable_route53 ? local.cf_acm_dvo : {}

#   zone_id = var.route53_zone_id
#   name    = each.value.name
#   type    = each.value.type
#   records = [each.value.value]
#   ttl     = 60
# }

# resource "aws_acm_certificate_validation" "cf_cert" {
#   provider = aws.us_east_1

#   certificate_arn         = aws_acm_certificate.cf_cert.arn
#   validation_record_fqdns = var.enable_route53 ? [for r in aws_route53_record.cf_cert_validation : r.fqdn] : []
# }

# resource "aws_route53_record" "apex_to_cloudfront" {
#   count   = var.enable_route53 ? 1 : 0

#   # In case the record already exists (e.g. from previous lab runs), allow overwriting it
#   # This is necessary because the same record will be created by both this lab and 
#   # the previous one (09-lab2_cloudfront_waf_and_distribution.tf)
#   allow_overwrite = true


#   zone_id = var.route53_zone_id
#   name    = var.domain_name
#   type    = "A"

#   alias {
#     name                   = aws_cloudfront_distribution.cf.domain_name
#     zone_id                = aws_cloudfront_distribution.cf.hosted_zone_id
#     evaluate_target_health = false
#   }
# }

# resource "aws_route53_record" "app_to_cloudfront" {
#   count   = var.enable_route53 ? 1 : 0
  
#   # In case the record already exists (e.g. from previous lab runs), allow overwriting it
#   # This is necessary because the same record will be created by both this lab and the previous one (09-lab2_cloudfront_waf_and_distribution.tf)
#   allow_overwrite = true


#   zone_id = var.route53_zone_id
#   name    = "${var.app_subdomain}.${var.domain_name}"
#   type    = "A"

#   alias {
#     name                   = aws_cloudfront_distribution.cf.domain_name
#     zone_id                = aws_cloudfront_distribution.cf.hosted_zone_id
#     evaluate_target_health = false
#   }
# }
