# ----------------------------------------------------------------------------
# 1. DATA SOURCES: Interrogate AWS for the correct Policy IDs
# ----------------------------------------------------------------------------
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


# Custom Policy to FORCE caching even if Flask says "no-cache"
resource "aws_cloudfront_cache_policy" "static_force" {
  name        = "Armageddon-Static-Force-Cache"
  comment     = "Ignores Origin no-cache headers by setting MinTTL"
  default_ttl = 86400    # 24 Hours
  max_ttl     = 31536000 # 1 Year
  min_ttl     = 60       # CRITICAL: Forces 60s cache minimum, overriding 'no-cache'

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

# ----------------------------------------------------------------------------
# 2. DISTRIBUTION: Use the dynamic IDs from the data sources
# ----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Armageddon Global Edge - Active/Passive"
  wait_for_deployment = false
  aliases             = [var.domain_name]
  web_acl_id          = var.waf_acl_id

  # 1. PRIMARY ORIGIN (Tokyo)
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "Primary-ALB"

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

  # 2. SECONDARY ORIGIN (São Paulo)
  dynamic "origin" {
    for_each = var.secondary_alb_dns_name != null ? [1] : []
    content {
      domain_name = var.secondary_alb_dns_name
      origin_id   = "Secondary-ALB"

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
  }

  # 3. ORIGIN GROUP (Failover Logic) - Only create if we have a secondary origin
  dynamic "origin_group" {
    for_each = var.secondary_alb_dns_name != null ? [1] : []
    
    content {
      origin_id = "Global-Failover-Group"

      failover_criteria {
        status_codes = [500, 502, 503, 504]
      }

      member {
        origin_id = "Primary-ALB"
      }

      member {
        origin_id = "Secondary-ALB"
      }
    }
  }

  # 4. DEFAULT BEHAVIOR - Point to the Origin Group if it exists, otherwise Primary ALB
  default_cache_behavior {
    # CRITICAL: Point to the GROUP ID, not the specific Origin
    target_origin_id       = var.secondary_alb_dns_name != null ? "Global-Failover-Group" : "Primary-ALB"
    
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = var.secondary_alb_dns_name != null ? "Global-Failover-Group" : "Primary-ALB"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.static_force.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  
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
}

