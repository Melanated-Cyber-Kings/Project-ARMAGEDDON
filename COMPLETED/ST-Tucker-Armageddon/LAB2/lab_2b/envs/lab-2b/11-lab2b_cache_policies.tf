###############################################################################
# LAB-2B — CloudFront Cache Policies + Origin Request Policies + Response Headers
# PURPOSE:
#   - /static/* : aggressive caching + explicit Cache-Control header
#   - /api/*    : caching disabled (safe default) but forwards what origin needs
#
# Notes:
#   - When caching is disabled (min/default/max TTL = 0), CloudFront REJECTS:
#       * enable_accept_encoding_gzip / brotli
#       * header_behavior other than "none" in the CACHE policy
#   - Authorization is NOT allowed in Origin Request Policy headers.
###############################################################################

##############################
# 1) Cache policy — static (aggressive)
##############################
resource "aws_cloudfront_cache_policy" "cache_static" {
  name        = "${local.name_prefix}-cache-static01"
  comment     = "Aggressive caching for /static/*"
  default_ttl = 86400    # 1 day
  max_ttl     = 31536000 # 1 year
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

##############################
# 2) Cache policy — api (caching disabled, safe default)
##############################
resource "aws_cloudfront_cache_policy" "cache_api_disabled" {
  name        = "${local.name_prefix}-cache-api-disabled01"
  comment     = "Disable caching for /api/* by default (safe default)"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  # When TTLs are all 0, CloudFront requires a very restricted config.
  # Keep cache key minimal/empty and do NOT enable gzip/brotli here.
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }
  }
}

##############################
# 3) Origin request policy — api (forward what origin needs)
##############################
resource "aws_cloudfront_origin_request_policy" "orp_api" {
  name    = "${local.name_prefix}-orp-api01"
  comment = "Forward necessary values for API calls (origin-facing), without caching them"

  cookies_config {
    cookie_behavior = "all"
  }

  query_strings_config {
    query_string_behavior = "all"
  }

  # Authorization is NOT allowed here by CloudFront validation.
  # Forward only what you truly need for your lab app.
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "Content-Type",
        "Origin",
        "Host",
        "Referer",
        "User-Agent",
        "Accept",
      ]
    }
  }
}

##############################
# 4) Origin request policy — static (minimal)
##############################
resource "aws_cloudfront_origin_request_policy" "orp_static" {
  name    = "${local.name_prefix}-orp-static01"
  comment = "Minimal forwarding for static assets"

  cookies_config {
    cookie_behavior = "none"
  }

  query_strings_config {
    query_string_behavior = "none"
  }

  headers_config {
    header_behavior = "none"
  }
}

##############################
# 5) Response headers policy — static explicit Cache-Control
##############################
resource "aws_cloudfront_response_headers_policy" "rsp_static" {
  name    = "${local.name_prefix}-rsp-static01"
  comment = "Add explicit Cache-Control for static content"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      override = true
      value    = "public, max-age=86400, immutable"
    }
  }
}
