# 1. Create the Hosted Zone specifically for the subdomain
resource "aws_route53_zone" "this" {
  name = var.domain_name 
  tags = { Name = "${var.name_prefix}-subdomain-zone" }
}

# 2. The Validation Records
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in var.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }... 
  }

  allow_overwrite = true
  name            = each.value[0].name
  records         = [each.value[0].record]
  ttl             = 60
  type            = each.value[0].type
  zone_id         = aws_route53_zone.this.zone_id
}

# 3. CloudFront Alias Record
resource "aws_route53_record" "edge_alias" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alias_dns_name
    zone_id                = var.alias_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "edge_alias_v6" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = var.alias_dns_name
    zone_id                = var.alias_zone_id
    evaluate_target_health = false
  }
}