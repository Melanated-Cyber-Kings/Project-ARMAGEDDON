# 1. Create the Hosted Zone specifically for the subdomain
resource "aws_route53_zone" "this" {
  name = var.domain_name 
  tags = { Name = "${var.name_prefix}-subdomain-zone" }
}

# 2. The Validation Records (Smart Key logic to handle unknown names)
resource "aws_route53_record" "validation" {
  # We use the domain_name as the key because it is a known static string
  for_each = {
    for dvo in var.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }... # The dots handle potential duplicates gracefully
  }

  allow_overwrite = true
  # We take the first instance of the grouped records
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