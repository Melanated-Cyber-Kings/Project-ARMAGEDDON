# ============================================
# Lab 2B: CloudFront Cache Correctness
# ============================================
# -------------------------------------------------
# 1. Cache Policy for Static Content (Aggressive)
# -------------------------------------------------
resource "aws_cloudfront_cache_policy" "chewbacca_cache_static01" {
  name    = "chewbacca-cache-static01"
  comment = "Aggressive caching for static content"
  default_ttl = 86400  # 24 hours in seconds
  max_ttl     = 31536000  # 1 year in seconds
  min_ttl     = 3600  # 1 hour in seconds
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
    enable_accept_encoding_gzip = true
    enable_accept_encoding_brotli = true
  }
}
# -------------------------------------------------
# 2. Cache Policy for API (Caching Disabled)
# -------------------------------------------------
resource "aws_cloudfront_cache_policy" "chewbacca_cache_api_disabled01" {
  name    = "chewbacca-cache-api-disabled01"
  comment = "No caching for API endpoints (safe default)"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0
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
  }
}
# -------------------------------------------------
# -------------------------------------------------
# 3. Origin Request Policy for API
# -------------------------------------------------
resource "aws_cloudfront_origin_request_policy" "chewbacca_orp_api01" {
  name    = "chewbacca-orp-api01"
  comment = "Forward required headers to API origin"
  cookies_config {
    cookie_behavior = "all"
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "Content-Type",
        "User-Agent"
      ]
    }
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}

# -------------------------------------------------
# 4. Origin Request Policy for Static (Minimal)
# -------------------------------------------------
resource "aws_cloudfront_origin_request_policy" "chewbacca_orp_static01" {
  name    = "chewbacca-orp-static01"
  comment = "Minimal forwarding for static content"
  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "Origin"
      ]
    }
  }
  query_strings_config {
    query_string_behavior = "none"
  }
}

# -------------------------------------------------
# 5. Origin Request Policy for Default (Everything else)
# -------------------------------------------------
resource "aws_cloudfront_origin_request_policy" "chewbacca_orp_default01" {
  name    = "chewbacca-orp-default01"
  comment = "Default policy for all other traffic"
  cookies_config {
    cookie_behavior = "all"
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "Content-Type",
        "Host",
        "User-Agent"
      ]
    }
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}
# -------------------------------------------------
# 6. Response Headers Policy (Simplified for testing)
# -------------------------------------------------
resource "aws_cloudfront_response_headers_policy" "chewbacca_response_headers01" {
  name    = "chewbacca-response-headers01"
  comment = "Add security and cache-control headers"
  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override = true
    }
    referrer_policy {
      referrer_policy = "same-origin"
      override = true
    }
    # REMOVE XSS protection - deprecated and can cause issues
    # xss_protection {
    #   mode_block = true
    #   protection = true
    #   override = true
    # }
    # Use simplified HSTS without preload for testing
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains = true
      preload = false  # Set to false during testing
      override = true
    }
  }
  custom_headers_config {
    items {
      header   = "Cache-Control"
      value    = "public, max-age=86400"
      override = true
    }
  }
}