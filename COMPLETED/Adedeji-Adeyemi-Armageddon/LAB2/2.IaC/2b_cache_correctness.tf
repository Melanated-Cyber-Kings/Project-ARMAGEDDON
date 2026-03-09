
##############################################################
# 1) Cache policy for static content (The "Hit" Maker)
##############################################################

# Explanation: We ignore cookies, headers, and query strings to ensure 
# CloudFront has one single "Key" for the file, forcing a HIT.
resource "aws_cloudfront_cache_policy" "chewbacca_cache_static01" {
  name        = "${var.project_name}-cache-static01"
  comment     = "Aggressive caching: Overrides Flask no-cache for /static/*"
  default_ttl = 86400        # 1 day
  max_ttl     = 31536000     # 1 year
  min_ttl     = 1            # Forces at least 1 second of caching even if origin is weird

  parameters_in_cache_key_and_forwarded_to_origin {
    # We set these to 'none' to maximize the cache hit ratio
    cookies_config { 
      cookie_behavior = "none" 
    }

    headers_config { 
      header_behavior = "none" 
    }

    # By setting this to none, v=1 and v=2 will share the same cache entry
    query_strings_config { 
      query_string_behavior = "none" 
    }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

# ##############################################################
# # 2) Cache policy for API (Disabled)
# ##############################################################
resource "aws_cloudfront_cache_policy" "chewbacca_cache_api_disabled01" {
  name        = "${var.project_name}-cache-api-disabled01"
  comment     = "Disable caching for /api/* and root"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config       { cookie_behavior = "none" }
    headers_config       { header_behavior = "none" }
    query_strings_config { query_string_behavior = "none" }
  }
}

# ##############################################################
# # 3) Origin request policy for API (The "Handshake" Carrier)
# ##############################################################
resource "aws_cloudfront_origin_request_policy" "chewbacca_orp_api01" {
  name    = "${var.project_name}-orp-api01"
  comment = "Forward secret for API and Root"
  cookies_config       { cookie_behavior = "all" }
  query_strings_config { query_string_behavior = "all" }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Content-Type", "Origin", "Host"]
    }
  }
}

# ##############################################################
# # 4) Origin request policy for static (Minimal but Secure)
# ##############################################################

resource "aws_cloudfront_origin_request_policy" "chewbacca_orp_static01" {
  name    = "${var.project_name}-orp-static01"
  comment = "Minimal forwarding for static assets"
  cookies_config       { cookie_behavior = "none" }
  query_strings_config { query_string_behavior = "none" }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Host"]
    }
  }
}


# ##############################################################
# # 5) Response headers policy (The "no-cache" Killer)
# ##############################################################
resource "aws_cloudfront_response_headers_policy" "chewbacca_rsp_static01" {
  name    = "${var.project_name}-rsp-static01"
  comment = "Force override of Flask no-cache headers"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      override = true # This is critical for getting a CACHE HIT
      value    = "public, max-age=86400, immutable"
    }
  }
}


# ##############################################################
# # 6) Distribution Behaviors (The Implementation)
# ##############################################################

# # NOTE: Copy these into your aws_cloudfront_distribution resource

# # 

# /*
#   # The Default Behavior (API/Dynamic/Root)
#   default_cache_behavior {
#     target_origin_id       = "chewbacca-alb-origin01"
#     viewer_protocol_policy = "redirect-to-https"

#     allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
#     cached_methods  = ["GET", "HEAD"]

#     cache_policy_id          = aws_cloudfront_cache_policy.chewbacca_cache_api_disabled01.id
#     origin_request_policy_id = aws_cloudfront_origin_request_policy.chewbacca_orp_api01.id
#   }

#   # The Static Behavior (The Speed Lane)
#   ordered_cache_behavior {
#     path_pattern           = "/static/*"
#     target_origin_id       = "chewbacca-alb-origin01"
#     viewer_protocol_policy = "redirect-to-https"

#     allowed_methods = ["GET", "HEAD", "OPTIONS"]
#     cached_methods  = ["GET", "HEAD"]

#     cache_policy_id            = aws_cloudfront_cache_policy.chewbacca_cache_static01.id
#     origin_request_policy_id   = aws_cloudfront_origin_request_policy.chewbacca_orp_static01.id
#     response_headers_policy_id = aws_cloudfront_response_headers_policy.chewbacca_rsp_static01.id
#   }
# 

resource "aws_cloudfront_cache_policy" "chewbacca_cache_saluki" {
  name        = "${var.project_name}-cache-saluki"
  comment     = "Beron Da Saluki: Respect Origin Cache Headers"
  min_ttl     = 1
  default_ttl = 1  # CloudFront uses this if the origin sends NO header
  max_ttl     = 31536000

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config { cookie_behavior = "none" }
    headers_config { header_behavior = "none" }
    query_strings_config { query_string_behavior = "none" }
  }
}