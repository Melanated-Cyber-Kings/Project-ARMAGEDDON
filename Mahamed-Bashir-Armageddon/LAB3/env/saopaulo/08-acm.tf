resource "aws_acm_certificate" "origin_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  tags              = local.tags
}