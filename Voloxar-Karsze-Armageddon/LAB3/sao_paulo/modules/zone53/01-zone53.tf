#get the domain name info from AWS
data "aws_route53_zone" "primary" {
  name         = var.domain_name
  private_zone = false
  
}

locals {
  full_url = "${var.subdomain}.${var.domain_name}"
  
}



############################################
# ACM Certificate
############################################

resource "aws_acm_certificate" "primary_certificate" {
  # Primary name (could be app or root, your choice)
  domain_name       = var.domain_name               # domain_name.com
  validation_method = "DNS"

  # Subject Alternative Names: root + wildcard
  subject_alternative_names = [
    var.domain_name,                                      # chewbacca-growl.com
    "*.${var.domain_name}",
  ]

  tags = {
    Name = "${var.project}-primary_cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}



############################################
# DNS validation records
############################################

resource "aws_route53_record" "primary_dns_validation" {
  # One record per domain_validation_option
  for_each = {
    for dvo in aws_acm_certificate.primary_certificate.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]

  allow_overwrite = true
}

############################################
# ACM certificate validation
############################################

resource "aws_acm_certificate_validation" "primary_acm_validation" {
  certificate_arn = aws_acm_certificate.primary_certificate.arn

  # Wait for all DNS records
  validation_record_fqdns = [
    for record in aws_route53_record.primary_dns_validation :
    record.fqdn
  ]
}

#lab2, cloudfront handles this now
# ############################################
# # ALIAS record: subdomain.domain_name -> ALB
# ############################################
# resource "aws_route53_record" "app_alias01" {
#   zone_id = data.aws_route53_zone.primary.zone_id
#   name    = local.full_url
#   type    = "A"

#   alias {
#     name                   = var.alb_dns_name
#     zone_id                = var.zone_id
#     evaluate_target_health = true
#   }
# }


# ############################################
# # ALIAS record: domain_name -> ALB
# ############################################
# resource "aws_route53_record" "app_alias02" {
#   zone_id = data.aws_route53_zone.primary.zone_id
#   name    = var.domain_name
#   type    = "A"

#   alias {
#     name                   = var.alb_dns_name
#     zone_id                = var.zone_id
#     evaluate_target_health = true
#   }
# }