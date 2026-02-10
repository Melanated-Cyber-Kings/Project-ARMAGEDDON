# Tokyo provider for ACM and ALB terraform doc
provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1"
}

resource "aws_route53_zone" "main" {
    name     = var.domain_name 

    tags = {
    Name = "${var.env_prefix}-route53-zone"
  }
}

# Create a new certificate do it only the first time 
# resource "aws_acm_certificate" "chewbacca_acm_cert01" {
#     provider = aws.tokyo
#     domain_name = var.domain_name

#     validation_method = "DNS"
#     subject_alternative_names =["*.${var.domain_name}", "${var.app_subdomain}.${var.domain_name}"]
# }

#Find a certificate that is issued
data "aws_acm_certificate" "chewbacca_acm_cert01" {
  provider = aws.tokyo
  domain   = var.domain_name
  statuses = ["PENDING_VALIDATION", "ISSUED"]
  most_recent = true
}


# Create validation records - terraform apply once
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.chewbacca_acm_cert01.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record.name
#       record = dvo.resource_record.value
#       type   = dvo.resource_record.type
#     } 
#   }

#   name            = each.value.name
#   type            = each.value.type
#   zone_id         = aws_route53_zone.main.zone_id
#   records         = [each.value.record]
#   ttl             = 300
#   allow_overwrite = true
# }

# Create validation records for ALL pending domains
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in data.aws_acm_certificate.chewbacca_acm_cert01.domain_validation_options : 
#     dvo.domain_name => {
#       name   = dvo.resource_record.name
#       record = dvo.resource_record.value
#       type   = dvo.resource_record.type
#       status = dvo.validation_status
#     } if dvo.validation_status == "PENDING_VALIDATION"
#   }

#   name            = each.value.name
#   type            = each.value.type
#   zone_id         = aws_route53_zone.main.zone_id
#   records         = [each.value.record]
#   ttl             = 300
#   allow_overwrite = true


#   # Wait for Route53 zone to be created
#   depends_on = [aws_route53_zone.main]
# }

# Create ALB DNS record (A record alias)
resource "aws_route53_record" "chewbacca_acm_validation" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "${var.app_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Only create certificate validation if you're creating a new certificat
# resource "aws_acm_certificate_validation" "chewbacca_acm_validation01" {
#   certificate_arn = data.aws_acm_certificate.chewbacca_acm_cert01.arn
#   validation_record_fqdns = [aws_route53_record.chewbacca_acm_validation.fqdn]
# }

# IMPORTANT: Create certificate validation resource
# This makes Terraform wait for validation to complete
resource "aws_acm_certificate_validation" "chewbacca_acm_validation01" {
  provider = aws.tokyo  # same provider
  
  certificate_arn = data.aws_acm_certificate.chewbacca_acm_cert01.arn
  
  # Use validation if records exist
  validation_record_fqdns =  []
  
  # Only wait if validation is needed
  timeouts {
    create = "45m"  # Allow time for DNS propagation
  }
}