# bonus_b_route53.tf
# Explanation: Chewbacca claims his corner of the galaxy with a Route53 hosted zone.
locals {
  # Determine zone ID: either create new or use existing
  chewbacca_zone_id = var.manage_route53_in_terraform ? aws_route53_zone.chewbacca_zone01[0].id : var.route53_hosted_zone_id
  
  # Fully qualified domain names
  chewbappa_apex_fqdn = var.domain_name
  chewbacca_app_fqdn  = "${var.app_subdomain}.${var.domain_name}"
}

# Create Route53 hosted zone IF we're managing it in Terraform
resource "aws_route53_zone" "chewbacca_zone01" {
  count = var.manage_route53_in_terraform ? 1 : 0
  
  name = var.domain_name
  
  tags = {
    Name = "${var.project_name}-zone"
  }
}

############################################
# ACM Certificate with DNS Validation
############################################

# Explanation: Chewbacca gets his TLS certificate—the galactic standard for secure communication.
resource "aws_acm_certificate" "chewbacca_acm_cert01" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "${var.app_subdomain}.${var.domain_name}"
  ]

  tags = {
    Name = "${var.project_name}-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Explanation: Route53 tells the galaxy this certificate is legitimate—DNS validation records.
resource "aws_route53_record" "chewbacca_acm_validation01" {
  for_each = {
    for dvo in aws_acm_certificate.chewbacca_acm_cert01.domain_validation_options : dvo.domain_name => {
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
  zone_id         = local.chewbacca_zone_id
}

# Explanation: Wait for the certificate authorities to confirm Chewbacca owns the domain.
resource "aws_acm_certificate_validation" "chewbacca_acm_validation01_dns_bonus" {
  certificate_arn = aws_acm_certificate.chewbacca_acm_cert01.arn
  
  validation_record_fqdns = [
    for record in aws_route53_record.chewbacca_acm_validation01 : record.fqdn
  ]
}

############################################
# ALIAS Records: Domain → ALB
############################################

# Explanation: The main entrance—chewbacca-growl.com points to your ALB.
resource "aws_route53_record" "chewbacca_apex_alias01" {
  zone_id = local.chewbacca_zone_id
  name    = local.chewbappa_apex_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.chewbacca_alb01.dns_name
    zone_id                = aws_lb.chewbacca_alb01.zone_id
    evaluate_target_health = true
  }
}

# Explanation: This is the holographic sign outside the cantina—app.chewbacca-growl.com points to your ALB.
resource "aws_route53_record" "chewbacca_app_alias01" {
  zone_id = local.chewbacca_zone_id
  name    = local.chewbacca_app_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.chewbacca_alb01.dns_name
    zone_id                = aws_lb.chewbacca_alb01.zone_id
    evaluate_target_health = true
  }
}