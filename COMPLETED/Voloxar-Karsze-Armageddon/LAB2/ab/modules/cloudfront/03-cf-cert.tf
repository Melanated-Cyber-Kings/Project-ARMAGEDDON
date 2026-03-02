
provider "aws" {
  region = "us-east-1"
}


# locals {
#   site_cert_dvo = tolist(aws_acm_certificate.site_cert.domain_validation_options)[0]
# }


resource "aws_acm_certificate" "site_cert" {
  #get the domain and the wildcard in one shot
  domain_name       = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project}-cf-cert"
  }
}


#from Perplexity
#https://www.perplexity.ai/search/todo-students-must-use-acm-cer-kCaYyUiFQUG31o7bkBVrdg

# resource "aws_route53_record" "site_cert_validation" {
#   zone_id = var.zone_id

#   name    = local.site_cert_dvo.resource_record_name
#   type    = local.site_cert_dvo.resource_record_type
#   ttl     = 60
#   records = [local.site_cert_dvo.resource_record_value]
# }

# resource "aws_acm_certificate_validation" "site_cert" {
#   provider                = aws.acm
#   certificate_arn         = aws_acm_certificate.site_cert.arn
#   validation_record_fqdns = [aws_route53_record.site_cert_validation.fqdn]
# }

