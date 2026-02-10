

# 1. Keep the Cache Policy minimal (Caching Disabled)
# from Google Gemini
resource "aws_cloudfront_cache_policy" "cache_api_disabled01" {
  name        = "${var.project}-cache-api-disabled01"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none" 
    }
    headers_config {
      header_behavior = "none" # Cache policy doesn't care about headers
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    
  }
}

#Use correct origin policy
#------------------------------------------
resource "aws_cloudfront_origin_request_policy" "orp_api01" {
  name = "${var.project}-orp-api01"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    # Changed from "all" to "allViewer" by Google Gemini
    # For headers in an ORP, you can't just say "all". 
    # You have to choose how you want those headers handled. 
    # Since you want to forward everything the user sends, 
    # the value you are looking for is "allViewer".
    header_behavior = "allViewer" 
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

##############################################
# Response headers policy (optional but nice)
##############################################
# Explanation: Make caching intent explicit—Chewbacca stamps Cache-Control so humans and CDNs agree.
resource "aws_cloudfront_response_headers_policy" "rsp_static01" {
  name    = "${var.project}-rsp-static01"
  comment = "Add explicit Cache-Control for static content"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      override = true
      value    = "public, max-age=86400, immutable"
    }
  }
}

##############################################
#Cache policy for static content (aggressive)
##############################################
# Explanation: Static files are the easy win—Chewbacca caches them like hyperfuel for speed.
resource "aws_cloudfront_cache_policy" "cache_static01" {
  name        = "${var.project}-cache-static01"
  comment     = "Aggressive caching for /static/*"
  default_ttl = 86400        # 1 day
  max_ttl     = 31536000     # 1 year
  min_ttl     = 3600         # 1 hour

  parameters_in_cache_key_and_forwarded_to_origin {
    # Explanation: Static should not vary on cookies—Chewbacca refuses to cache 10,000 versions of a PNG.
    cookies_config { cookie_behavior = "none" }

    # Explanation: Static should not vary on query strings (unless you do versioning); students can change later.
    query_strings_config { query_string_behavior = "none" }

    # Explanation: Keep headers out of cache key to maximize hit ratio.
    headers_config { header_behavior = "none" }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

############################################
#Origin request policy for static (minimal)
############################################
# Explanation: Static origins need almost nothing—Chewbacca forwards minimal values for maximum cache sanity.
# resource "aws_cloudfront_origin_request_policy" "orp_static01" {
#   name    = "${var.project}-orp-static01"
#   comment = "Minimal forwarding for static assets"

#   cookies_config { cookie_behavior = "none" }
#   query_strings_config { query_string_behavior = "none" }
#   headers_config { header_behavior = "none" }
# }

#corrected by chatgpt & perplexity
resource "aws_cloudfront_origin_request_policy" "orp_static01" {
  name    = "${var.project}-orp-static01"
  comment = "Minimal forwarding for static assets"

  cookies_config {
    cookie_behavior = "none"
  }
  
  query_strings_config {
    query_string_behavior = "none"
  }
  
  #cloudfront wasn't working until this was added
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Host"] 
    }
  }
}