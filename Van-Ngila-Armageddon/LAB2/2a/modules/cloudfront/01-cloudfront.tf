# Explanation: This is shinjuku’s secret handshake — if the header isn’t present, you don’t get in.
resource "random_password" "shinjuku_origin_header_value01" {
  length  = 32
  special = false
}

# Explanation: CloudFront is the only public doorway — shinjuku stands behind it with private infrastructure.
resource "aws_cloudfront_distribution" "shinjuku_cf01" {
  provider = aws.virginia
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.env_prefix}-cf01"

  origin {
    origin_id   = "${var.env_prefix}-alb-origin01"
    domain_name = var.alb_dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    # Explanation: CloudFront whispers the secret header — the ALB only trusts this.
    custom_header {
      name  = "X-theowaf-homework"
      value = random_password.shinjuku_origin_header_value01.result
    }
  }

  default_cache_behavior {
    target_origin_id       = "${var.env_prefix}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    # Use modern cache policies (Lab 2B)
    cache_policy_id          = var.cache_policy_api_id
    origin_request_policy_id = var.origin_request_policy_api_id
    
    # Fallback to legacy forwarded_values if policies not provided (backward compatibility)
    dynamic "forwarded_values" {
      for_each = var.cache_policy_api_id == null ? [1] : []
      content {
        query_string = true
        headers      = ["*"]
        cookies { forward = "all" }
      }
    }
  }

  # ORDERED CACHE BEHAVIORS (for specific path patterns like /static/*)
  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    
    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      target_origin_id       = "${var.env_prefix}-alb-origin01"
      viewer_protocol_policy = "redirect-to-https"
      
      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      
      cache_policy_id            = ordered_cache_behavior.value.cache_policy_id
      origin_request_policy_id   = ordered_cache_behavior.value.origin_request_policy_id
      response_headers_policy_id = lookup(ordered_cache_behavior.value, "response_headers_policy_id", null)
    }
  }

  # Explanation: Attach WAF at the edge — now WAF moved to CloudFront.
  web_acl_id = aws_wafv2_web_acl.shinjuku_cf_waf01.arn

  aliases = [
    var.domain_name,
    "${var.app_subdomain}.${var.domain_name}"
  ]

  # TODO: students must use ACM cert in us-east-1 for CloudFront
  viewer_certificate {
    acm_certificate_arn      = var.cloudfront_acm_cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}