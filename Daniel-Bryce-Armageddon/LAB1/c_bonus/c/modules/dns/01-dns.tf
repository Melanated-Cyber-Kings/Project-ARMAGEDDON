# Tokyo provider for ACM 
provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1"
}

# 1. Manage Route53 Zone conditionally
resource "aws_route53_zone" "main" {
  count = var.manage_route53_in_terraform ? 1 : 0
  name  = var.domain_name

  tags = {
    Name = "${var.env_prefix}-route53-zone"
  }
}

# Local to determine which Zone ID to use (New vs Existing)#Replaced and can be found in B
locals {
  zone_id = var.manage_route53_in_terraform ? aws_route53_zone.main[0].zone_id : var.route53_hosted_zone_id
}

# 2. ACM Certificate 
resource "aws_acm_certificate" "chewbacca_acm_cert01" {
  provider                  = aws.tokyo
  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = ["*.${var.domain_name}", "${var.app_subdomain}.${var.domain_name}"]

  lifecycle {
    ignore_changes = [
      domain_validation_options,
      status,
      validation_method
    ]
    prevent_destroy = true
  }
}

# 3. Validation Records 
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.chewbacca_acm_cert01.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record.name
      record = dvo.resource_record.value
      type   = dvo.resource_record.type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.zone_id

  lifecycle {
    prevent_destroy = true
  }
}

# 4. Wait for Certificate Validation 
resource "aws_acm_certificate_validation" "chewbacca_acm_validation01" {
  provider                = aws.tokyo
  certificate_arn         = aws_acm_certificate.chewbacca_acm_cert01.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "45m"
  }
}

# 5. Application DNS Record (A Record alias to ALB)
resource "aws_route53_record" "app_record" {
  zone_id = local.zone_id
  name    = "${var.app_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
