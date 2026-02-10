###############################################################################
# acm.tf
# Module: ingress (Lab-1C Bonus C)
###############################################################################

resource "aws_acm_certificate" "app_cert" {
  domain_name       = local.app_fqdn
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Only create ACM validation when Terraform is managing Route53 records.
resource "aws_acm_certificate_validation" "app_cert_validation" {
  count           = local.is_route53 ? 1 : 0
  certificate_arn = aws_acm_certificate.app_cert.arn

  validation_record_fqdns = aws_route53_record.acm_validation[*].fqdn
}
