

# lab2_cloudfront_r53.tf - Lab 2A

locals {
  zone_id   = "Z064076128W8FV0DP91X1"  # Your existing zone
  apex_fqdn = "givenchyops.com"
  app_fqdn  = "app.givenchyops.com"
}

############################################
# ACM Certificate in us-east-1 for CloudFront
############################################
resource "aws_acm_certificate" "cloudfront_cert" {
  provider = aws.us-east-1

  domain_name       = local.apex_fqdn
  validation_method = "DNS"

  subject_alternative_names = [
    "*.givenchyops.com",
    #"*.ap-northeast-1.elb.amazonaws.com",
    local.app_fqdn
  ]

  lifecycle { 
    create_before_destroy = true
    #ignore_changes = [subject_alternative_names]
   }
}

# DNS validation
resource "aws_route53_record" "cloudfront_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.zone_id
}

resource "aws_acm_certificate_validation" "cloudfront_cert_validation" {
  provider = aws.us-east-1
  certificate_arn = aws_acm_certificate.cloudfront_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_cert_validation : record.fqdn]
}

############################################
# UPDATE Existing Route53 Records to CloudFront
############################################

# Update existing apex record to point to CloudFront
resource "aws_route53_record" "apex_to_cloudfront" {
  allow_overwrite = true
  zone_id = local.zone_id
  name    = local.apex_fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.chewbacca_cf01.domain_name
    zone_id                = aws_cloudfront_distribution.chewbacca_cf01.hosted_zone_id
    evaluate_target_health = false
  }
}

# Update existing app record to point to CloudFront
resource "aws_route53_record" "app_to_cloudfront" {
  allow_overwrite = true
  zone_id = local.zone_id
  name    = local.app_fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.chewbacca_cf01.domain_name
    zone_id                = aws_cloudfront_distribution.chewbacca_cf01.hosted_zone_id
    evaluate_target_health = false
  }
}
