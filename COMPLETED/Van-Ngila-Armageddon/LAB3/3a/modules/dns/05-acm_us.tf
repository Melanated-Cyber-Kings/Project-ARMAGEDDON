# N. Virginia provider for ACM
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

# Route53 Zone
data "aws_route53_zone" "main" {
  name = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "cloudfront_cert" {
  provider = aws.virginia
  
  domain_name       = var.domain_name
  validation_method = "DNS"
  
  subject_alternative_names = [
    "*.${var.domain_name}", "${var.app_subdomain}.${var.domain_name}"
  ]
  
  lifecycle {
    create_before_destroy = true
  }
}

# Update validation records (Route53 is global)
resource "aws_route53_record" "cloudfront_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  
  allow_overwrite = true  # CRITICAL
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}