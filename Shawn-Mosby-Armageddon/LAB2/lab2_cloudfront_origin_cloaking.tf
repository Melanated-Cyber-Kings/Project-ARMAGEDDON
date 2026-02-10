###########################################################
# 1. Look up the Managed Prefix List for CloudFront
###########################################################
data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

###########################################################
# 2. Update the ALB Security Group Ingress
###########################################################

# First, we remove the old "Open to the World" rule if it exists.
# Then, we add this rule to allow ONLY CloudFront IPs.
resource "aws_vpc_security_group_ingress_rule" "alb_allow_cloudfront_only" {
  security_group_id = aws_security_group.chewbacca_alb_sg01.id

  description    = "Allow HTTPS only from CloudFront Managed Prefix List"
  from_port      = 443
  to_port        = 443
  ip_protocol    = "tcp"
  prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.id
}

# acts as password between clouldfront and and ALB
resource "random_password" "origin_secret" {
  length  = 32
  special = false
}

###########################################################
# 1. Update the HTTPS Listener's Default Action
###########################################################
# This tells the ALB: "If no rules match, give them a 403"
resource "aws_lb_listener" "chewbacca_https_listener01" {
  load_balancer_arn = aws_lb.chewbacca_alb01.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.chewbacca_acm_validation01_dns_bonus[0].certificate_arn # Use your existing cert variable

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied: Missing Origin Shield"
      status_code  = "403"
    }
  }
}

###########################################################
# 2. Add the "Secret Handshake" Rule
###########################################################
resource "aws_lb_listener_rule" "allow_cloudfront_header" {
  listener_arn = aws_lb_listener.chewbacca_https_listener01.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chewbacca_tg01.arn
  }

  condition {
    http_header {
      http_header_name = "X-Chewbacca-Growl"
      values           = [random_password.origin_secret.result]
    }
  }
}

resource "aws_cloudfront_distribution" "chewbacca_cf01" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront for Chewbacca Growl"
  # This is the Global WAF you will create in the next step
  web_acl_id = aws_wafv2_web_acl.chewbacca_cf_waf01.arn
  aliases = ["lewsdomain.com", "app.lewsdomain.com"]

  origin {
    domain_name = aws_lb.chewbacca_alb01.dns_name
    origin_id   = "chewbacca-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # Security first!
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    # THIS IS THE SECRET HANDSHAKE
    custom_header {
      name  = "X-Chewbacca-Growl"
      value = random_password.origin_secret.result
    }
  }

  ordered_cache_behavior {
  path_pattern           = "/safe-data"
  target_origin_id       = "chewbacca-alb-origin"
  viewer_protocol_policy = "redirect-to-https"
  allowed_methods        = ["GET", "HEAD"]
  cached_methods         = ["GET", "HEAD"]

  cache_policy_id          = aws_cloudfront_cache_policy.chewbacca_cache_saluki.id
  origin_request_policy_id = aws_cloudfront_origin_request_policy.chewbacca_orp_api01.id
}

ordered_cache_behavior {
  path_pattern           = "/api/*"
  target_origin_id       = "chewbacca-alb-origin"
  viewer_protocol_policy = "redirect-to-https"
  allowed_methods        = ["GET", "HEAD", "OPTIONS"]
  cached_methods         = ["GET", "HEAD"]

  # USE A POLICY THAT ALLOWS CACHING
  # Using the "CachingOptimized" managed policy is usually best for this
  cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" 
  
  # Or use your 'chewbacca_cache_saluki' if that one has TTLs > 0
  # cache_policy_id = aws_cloudfront_cache_policy.chewbacca_cache_saluki.id

  origin_request_policy_id = aws_cloudfront_origin_request_policy.chewbacca_orp_api01.id
}
  default_cache_behavior {
    target_origin_id       = "chewbacca-alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id          = aws_cloudfront_cache_policy.chewbacca_cache_api_disabled01.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.chewbacca_orp_api01.id
  }

  ordered_cache_behavior {
    path_pattern     = "/static/*"
    target_origin_id = "chewbacca-alb-origin" # Match your origin_id
    
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    # Point to the policies from Step 1, 4, and 5
    cache_policy_id            = aws_cloudfront_cache_policy.chewbacca_cache_static01.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.chewbacca_orp_static01.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.chewbacca_rsp_static01.id
    
    viewer_protocol_policy = "redirect-to-https"
  }

  # Use the certificate from us-east-1 here!
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.chewbacca_cf_cert_us_east_1.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# The Global Certificate for CloudFront
resource "aws_acm_certificate" "chewbacca_cf_cert_us_east_1" {
  provider          = aws.us_east_1 # THIS IS THE KEY
  domain_name       = "lewsdomain.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "app.lewsdomain.com"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# 1. Create the DNS Records in your existing Hosted Zone
resource "aws_route53_record" "cf_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.chewbacca_cf_cert_us_east_1.domain_validation_options : dvo.domain_name => {
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
  zone_id         = aws_route53_zone.chewbacca_zone01[0].zone_id # Use your existing zone data source
}

# 2. Trigger the actual validation
resource "aws_acm_certificate_validation" "cf_cert_validate" {
  provider                = aws.us_east_1 # MUST match the certificate provider
  certificate_arn         = aws_acm_certificate.chewbacca_cf_cert_us_east_1.arn
  validation_record_fqdns = [for record in aws_route53_record.cf_cert_validation : record.fqdn]
}

# This data source finds the built-in AWS policy for forwarding all headers
data "aws_cloudfront_origin_request_policy" "all_viewer_headers" {
  name = "Managed-AllViewer"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

# Custom "Caching Disabled" Policy ----- For lab 2a, commented out for lab 2b
# resource "aws_cloudfront_cache_policy" "chewbacca_no_cache" {
#   name        = "Chewbacca-CachingDisabled"
#   comment     = "Custom caching disabled policy for Lab 2"
#   default_ttl = 0
#   max_ttl     = 0
#   min_ttl     = 0
  
#   parameters_in_cache_key_and_forwarded_to_origin {
#     cookies_config {
#       cookie_behavior = "none"
#     }
#     headers_config {
#       header_behavior = "none"
#     }
#     query_strings_config {
#       query_string_behavior = "none"
#     }
#   }
# }

# Custom "All Viewer" Origin Request Policy
resource "aws_cloudfront_origin_request_policy" "chewbacca_all_viewer" {
  name    = "Chewbacca-AllViewer"
  comment = "Custom policy to forward all headers for Origin Cloaking"
  
  cookies_config {
    cookie_behavior = "all"
  }
  headers_config {
    header_behavior = "allViewer"
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_lb_listener" "chewbacca_http_listener01" {
  load_balancer_arn = aws_lb.chewbacca_alb01.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chewbacca_tg01.arn
  }
}