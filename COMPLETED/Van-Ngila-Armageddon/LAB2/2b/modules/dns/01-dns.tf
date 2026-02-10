# # Tokyo provider for ACM and ALB terraform doc
# provider "aws" {
#   alias  = "tokyo"
#   region = "ap-northeast-1"
# }

# resource "aws_route53_zone" "main" {
#     name     = var.domain_name 

#     tags = {
#     Name = "${var.env_prefix}-route53-zone"
#   }
# }

# Create a new certificate do it only the first time 
# resource "aws_acm_certificate" "shinjuku_acm_cert01" {
#     provider = aws.tokyo
#     domain_name = var.domain_name

#     validation_method = "DNS"
#     subject_alternative_names =["*.${var.domain_name}", "${var.app_subdomain}.${var.domain_name}"]

#     tags = {
#     Name = "${var.env_prefix}-acm-cert"
#   }
  
#   # Important: Don't create until Route53 zone exists
#   depends_on = [aws_route53_zone.main]
# }

#Find a certificate that is issued
# data "aws_acm_certificate" "shinjuku_acm_cert01" {
#   provider = aws.tokyo
#   domain   = var.domain_name
#   statuses = ["PENDING_VALIDATION", "ISSUED"]
#   most_recent = true
# }


# Create validation records - terraform apply once
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.shinjuku_acm_cert01.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     } 
#   }

#   name            = each.value.name
#   type            = each.value.type
#   zone_id         = aws_route53_zone.main.zone_id
#   records         = [each.value.record]
#   ttl             = 300
#   allow_overwrite = true

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# Create validation records for ALL pending domains
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in data.aws_acm_certificate.shinjuku_acm_cert01.domain_validation_options : 
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
# resource "aws_route53_record" "shinjuku_acm_validation" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "${var.app_subdomain}.${var.domain_name}"
#   type    = "A"

#   alias {
#     name                   = var.alb_dns_name
#     zone_id                = var.alb_zone_id
#     evaluate_target_health = true
#   }
# }
## BONUS C
# resource "aws_route53_record" "app_alias" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "${var.app_subdomain}.${var.domain_name}"  # "app.theowafhomework.site"
#   type    = "A"

#   alias {
#     name                   = var.alb_dns_name          # Need to pass this from network module
#     zone_id                = var.alb_zone_id           # Need to pass this from network module
#     evaluate_target_health = true
#   }
# }

# Only create certificate validation if you're creating a new certificat
# resource "aws_acm_certificate_validation" "shinjuku_acm_validation01" {
#   certificate_arn = data.aws_acm_certificate.shinjuku_acm_cert01.arn
#   validation_record_fqdns = [aws_route53_record.shinjuku_acm_validation.fqdn]
# }

# IMPORTANT: Create certificate validation resource
# This makes Terraform wait for validation to complete
# resource "aws_acm_certificate_validation" "shinjuku_acm_validation01" {
#   provider = aws.tokyo  # same provider
  
#   certificate_arn = aws_acm_certificate.shinjuku_acm_cert01.arn
  
#   # Use validation if records exist
#   validation_record_fqdns =  [ for record in aws_route53_record.cert_validation : record.fqdn ]
  
#   # Only wait if validation is needed
#   timeouts {
#     create = "45m"  # Allow time for DNS propagation
#   }
# }

# Tokyo provider for ACM and ALB terraform doc
# provider "aws" {
#   alias  = "tokyo"
#   region = "ap-northeast-1"
# }

# resource "aws_route53_zone" "main" {
#   name = var.domain_name
#   tags = {
#     Name = "${var.env_prefix}-route53-zone"
#   }
# }

# # -------------------------------------------------------------------
# # USE EXISTING CERTIFICATE (not create new one)
# # -------------------------------------------------------------------
# data "aws_acm_certificate" "shinjuku_acm_cert01" {
#   provider = aws.tokyo
#   domain   = var.domain_name
#   statuses = ["ISSUED"]  # Only ISSUED certificates
#   most_recent = true
# }

# # -------------------------------------------------------------------
# # CHECK VALIDATION RECORDS EXIST (optional, for verification)
# # -------------------------------------------------------------------
# data "aws_route53_zone" "selected" {
#   name = var.domain_name
# }

# data "aws_route53_records" "cert_validation_check" {
#   zone_id = data.aws_route53_zone.selected.zone_id
  
# }

# # -------------------------------------------------------------------
# # ALIAS record for app -> ALB (Bonus C requirement)
# # -------------------------------------------------------------------
# resource "aws_route53_record" "app_alias" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "${var.app_subdomain}.${var.domain_name}"
#   type    = "A"

#   alias {
#     name                   = var.alb_dns_name
#     zone_id                = var.alb_zone_id
#     evaluate_target_health = true
#   }
# }

# # -------------------------------------------------------------------
# # CREATE APEX RECORD FOR BONUS D (theowafhomework.site -> ALB)
# # -------------------------------------------------------------------
# resource "aws_route53_record" "apex_alias" {
#   count = var.create_apex_record ? 1 : 0
  
#   zone_id = aws_route53_zone.main.zone_id
#   name    = var.domain_name  # "theowafhomework.site" (no subdomain)
#   type    = "A"

#   alias {
#     name                   = var.alb_dns_name
#     zone_id                = var.alb_zone_id
#     evaluate_target_health = true
#   }
# }

# provider "aws" {
#   alias  = "tokyo"
#   region = "ap-northeast-1"
# }

# # Route53 Zone
# resource "aws_route53_zone" "main" {
#   name = var.domain_name
#   tags = {
#     Name = "${var.env_prefix}-route53-zone"
#   }
# }

# # KEEP as RESOURCE (not data source) with ignore_changes
# resource "aws_acm_certificate" "shinjuku_acm_cert01" {
#   provider = aws.tokyo
#   domain_name = var.domain_name
#   validation_method = "DNS"
#   subject_alternative_names = ["*.${var.domain_name}", "${var.app_subdomain}.${var.domain_name}"]

  
  
#   # CRITICAL: This prevents Terraform from modifying the existing certificate
#   lifecycle {
#     ignore_changes = [
#       validation_method,          # Keep as DNS validation
#       subject_alternative_names   # Keep existing SANs
#     ]
#     prevent_destroy = true  # NEVER delete this certificate
#   }
#   tags = {
#     Name = "${var.env_prefix}-acm-cert"
#   }
# }

# # KEEP validation records (prevent destruction)
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.shinjuku_acm_cert01.domain_validation_options : 
#     dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   name            = each.value.name
#   type            = each.value.type
#   zone_id         = aws_route53_zone.main.zone_id
#   records         = [each.value.record]
#   ttl             = 300
#   allow_overwrite = true

#   # CRITICAL: Never delete validation records
#   lifecycle {
#     prevent_destroy = true
#   }
# }

# # ALIAS record for app -> ALB
# resource "aws_route53_record" "app_alias" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "${var.app_subdomain}.${var.domain_name}"
#   type    = "A"

#   alias {
#     name                   = var.alb_dns_name
#     zone_id                = var.alb_zone_id
#     evaluate_target_health = true
#   }
# }

# Tokyo provider for ACM
provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1"
}

# Route53 Zone
resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = {
    Name = "${var.env_prefix}-route53-zone"
  }
}

# Resource for ACM certificate with lifecycle to prevent changes
resource "aws_acm_certificate" "chewbacca_acm_cert01" {
  provider = aws.tokyo
  
  # These are required by Terraform but will be ignored due to lifecycle
  domain_name       = var.domain_name
  validation_method = "DNS"
  
  # CRITICAL: This prevents Terraform from trying to modify the certificate
  lifecycle {
    ignore_changes = [
      domain_name,
      validation_method,
      subject_alternative_names,
      options,
      tags,
      tags_all
    ]
    prevent_destroy = true
  }
}

# Validation records - these are what we actually want Terraform to manage
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.chewbacca_acm_cert01.domain_validation_options : 
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name            = each.value.name
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
  records         = [each.value.record]
  ttl             = 300
  allow_overwrite = true

  # lifecycle {
  #   prevent_destroy = true
  # }
  # # SMART LIFECYCLE: Only prevent destroy for ISSUED certificates
  # lifecycle {
  #   prevent_destroy = aws_acm_certificate.shinjuku_acm_cert01.status == "ISSUED"
  #   ignore_changes = [
  #     # Allow validation record values to change during renewal
  #     records,
  #     name
  #   ]
  # }
  lifecycle {
    # Allow validation records to be replaced during certificate changes
    prevent_destroy = false
    
    # Optional: Ignore value changes (certificate renewals)
    ignore_changes = [
      records,
      name
    ]
  }
}

# ALIAS record for app -> ALB
##LAB2
# Explanation: DNS now points to CloudFront — nobody should ever see the ALB again.
resource "aws_route53_record" "app_alias" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "${var.app_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.shinjuku_cf01_domain_name
    zone_id                = var.shinjuku_cf01_hosted_zone_id
    evaluate_target_health = true
  }
}

# Explanation: app.theowafhomework.site also points to CloudFront — same doorway, different sign.
resource "aws_route53_record" "apex_alias" {
  count = var.create_apex_record ? 1 : 0
  
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name  # "theowafhomework.site" (no subdomain)
  type    = "A"

  alias {
    name                   = var.shinjuku_cf01_domain_name
    zone_id                = var.shinjuku_cf01_hosted_zone_id
    evaluate_target_health = true
  }
}