#############################################
### Route53  and Certificate on HTTPS Listener
#############################################
# Get your existing Route 53 Zone info
data "aws_route53_zone" "main" {
  name         = "mycompanyikeep.click"
  private_zone = false
}

# Request the Certificate
resource "aws_acm_certificate" "cert" {
  domain_name       = "mycompanyikeep.click"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create the DNS record to prove you own the domain
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.main.zone_id
}

# Wait for validation to complete
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

#############################################
### Point the Domain to the ALB
#############################################
resource "aws_route53_record" "root_a" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "mycompanyikeep.click"
  type    = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.lab1_alb.dns_name
    zone_id                = aws_lb.lab1_alb.zone_id
    evaluate_target_health = true
  }
}