# --- ORIGIN CERTIFICATE (Tokyo) ---
resource "aws_acm_certificate" "origin_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  tags              = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# --- EDGE CERTIFICATE (Virginia) ---
resource "aws_acm_certificate" "edge_cert" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"
  tags              = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Wait for Tokyo Cert Validation
resource "aws_acm_certificate_validation" "origin" {
  certificate_arn         = aws_acm_certificate.origin_cert.arn
   validation_record_fqdns = module.dns.validation_record_fqdns
}

# Wait for Edge Cert Validation (CRITICAL FOR CLOUDFRONT)
resource "aws_acm_certificate_validation" "edge" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.edge_cert.arn
   validation_record_fqdns = module.dns.validation_record_fqdns
}