data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

data "aws_cloudfront_cache_policy" "origin_driven" {
  name = "UseOriginCacheControlHeaders"
}


# Custom Policy to FORCE caching
resource "aws_cloudfront_cache_policy" "static_force" {
  name        = "Armageddon-Static-Force-Cache"
  comment     = "Ignores Origin no-cache headers by setting MinTTL"
  default_ttl = 86400    # 24 Hours
  max_ttl     = 31536000 # 1 Year
  min_ttl     = 60       #Forces 60s cache minimum, overriding 'no-cache'

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}


resource "aws_cloudfront_response_headers_policy" "static_hardening" {
  name    = "${var.name_prefix}-static-hardening"
  comment = "Hardened Cache-Control for Static Assets"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      override = true 
      value    = "public, max-age=86400, immutable"
    }
  }
}
# ----------------------------------------------------------------------------
# 2. DISTRIBUTION: Uses the dynamic IDs from the data sources
# ----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Armageddon Optimized Edge - Lab 2B"
  wait_for_deployment = false

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "ALB-Origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = var.secret_header_name
      value = var.secret_header_value
    }
  }

  # BEHAVIOR 1: DEFAULT (API / Dynamic / Origin-Driven)
  default_cache_behavior {
    target_origin_id       = "ALB-Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.origin_driven.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  # BEHAVIOR 2: STATIC ASSETS (AGGRESSIVE CACHE)
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "ALB-Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.static_force.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.static_hardening.id
  }

  web_acl_id = var.waf_acl_id

  logging_config {
    bucket          = "${var.log_bucket_name}.s3.amazonaws.com"
    include_cookies = false
    prefix          = "cf-logs/"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = [var.domain_name]
}