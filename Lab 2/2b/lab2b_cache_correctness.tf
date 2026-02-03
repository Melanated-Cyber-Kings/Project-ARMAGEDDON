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
      cookie_behavior = "none"  # Don't include cookies in cache key
    }
    
    headers_config {
      header_behavior = "none"  # Don't include headers in cache key
    }
    
    query_strings_config {
      query_string_behavior = "none"  # Don't include query strings in cache key
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
  
  default_ttl = 0  # No caching
  max_ttl     = 0  # No caching
  min_ttl     = 0  # No caching
  
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "all"  # Include all cookies in cache key
    }
    
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Authorization", "Content-Type", "User-Agent"]
      }
    }
    
    query_strings_config {
      query_string_behavior = "all"  # Include all query strings in cache key
    }
    
    enable_accept_encoding_gzip = true
    enable_accept_encoding_brotli = true
  }
}

# -------------------------------------------------
# 3. Origin Request Policy for API
# -------------------------------------------------
resource "aws_cloudfront_origin_request_policy" "chewbacca_orp_api01" {
  name    = "chewbacca-orp-api01"
  comment = "Forward required headers to API origin"
  
  cookies_config {
    cookie_behavior = "all"  # Forward all cookies to origin
  }
  
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "Authorization",
        "Content-Type",
        "User-Agent",
        "X-Chewbacca-Growl"  # Your custom header for origin cloaking
      ]
    }
  }
  
  query_strings_config {
    query_string_behavior = "all"  # Forward all query strings
  }
}

# -------------------------------------------------
# 4. Origin Request Policy for Static (Minimal)
# -------------------------------------------------
resource "aws_cloudfront_origin_request_policy" "chewbacca_orp_static01" {
  name    = "chewbacca-orp-static01"
  comment = "Minimal forwarding for static content"
  
  cookies_config {
    cookie_behavior = "none"  # Don't forward cookies
  }
  
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "Origin",  # For CORS
        "X-Chewbacca-Growl"  # Your custom header for origin cloaking
      ]
    }
  }
  
  query_strings_config {
    query_string_behavior = "none"  # Don't forward query strings
  }
}

# -------------------------------------------------
# 5. Response Headers Policy (Optional Bonus)
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
    
    xss_protection {
      mode_block = true
      protection = true
      override = true
    }
    
    strict_transport_security {
      access_control_max_age_sec = 31536000  # 1 year
      include_subdomains = true
      preload = true
      override = true
    }
  }
  
  custom_headers_config {
    items {
      header   = "Cache-Control"
      value    = "public, max-age=86400"  # 24 hours
      override = true
    }
  }
}

# -------------------------------------------------
# 6. Update CloudFront Distribution Behaviors
# -------------------------------------------------
# IMPORTANT: This data source gets your existing CloudFront distribution
