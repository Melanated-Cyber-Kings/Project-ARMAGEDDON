# Explanation: CloudFront is the only public doorway — Chewbacca stands behind it with private infrastructure.
resource "aws_cloudfront_distribution" "ccf01" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project}-cf01"

  origin {
    origin_id   = "${var.project}-alb-origin01"
    domain_name = var.alb_dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      
    
    origin_read_timeout    = 60
    origin_keepalive_timeout = 5

      
      #from chatgpt, 504 errors
      #origin_read_timeout    = 60   # seconds
      #origin_keepalive_timeout = 5
    }

    # Explanation: CloudFront whispers the secret growl — the ALB only trusts this.
    custom_header {
      name  = "X-Chewbacca-Growl"
      value = random_password.origin_header_value01.result
    }
  }

  # default_cache_behavior {
  #   target_origin_id       = "${var.project}-alb-origin01"
  #   viewer_protocol_policy = "redirect-to-https"

  #   allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
  #   cached_methods  = ["GET", "HEAD"]

  #   # TODO: students choose cache policy / origin request policy for their app type
  #   # For APIs, typically forward all headers/cookies/querystrings.
  #   forwarded_values {
  #     query_string = true
  #     headers      = ["*"]
  #     cookies { forward = "all" }
  #   }
  # }

  default_cache_behavior {   # <--- your block goes here
    target_origin_id       = "${var.project}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]
    
    #swapped, let the origin headers speak
    #cache_policy_id          = aws_cloudfront_cache_policy.cache_api_disabled01.id

    cache_policy_id = data.aws_cloudfront_cache_policy.use_origin_cache.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.orp_api01.id
  }

  # optional ordered behaviors for /static/* etc.
  # ordered_cache_behavior {
  #   path_pattern            = "/static/*"
    
  #   allowed_methods = ["GET","HEAD","OPTIONS"]
  #   cached_methods  = ["GET","HEAD"]

  #   target_origin_id        = "${var.project}-alb-origin01"
  #   cache_policy_id         = aws_cloudfront_cache_policy.cache_static01.id
  #   origin_request_policy_id = aws_cloudfront_origin_request_policy.orp_static01.id
  #   viewer_protocol_policy  = "redirect-to-https"
  # }
 ordered_cache_behavior {
  path_pattern            = "/static/*"
  
  allowed_methods = ["GET", "HEAD", "OPTIONS"]
  cached_methods  = ["GET", "HEAD"]
  
  target_origin_id        = "${var.project}-alb-origin01"
  
  cache_policy_id         = aws_cloudfront_cache_policy.cache_static01.id
  origin_request_policy_id = aws_cloudfront_origin_request_policy.orp_static01.id
  viewer_protocol_policy  = "redirect-to-https"
  
  # NO forwarded_values block needed - policies handle everything
}




 # Explanation: Attach WAF at the edge — now WAF moved to CloudFront.
  web_acl_id = aws_wafv2_web_acl.cf_waf01.arn


  # TODO: students set aliases for chewbacca-growl.com and app.chewbacca-growl.com
  aliases = [
    var.domain_name,
    "${var.subdomain}.${var.domain_name}"
  ]

  # TODO: students must use ACM cert in us-east-1 for CloudFront
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.site_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

    lifecycle {
    create_before_destroy = true
  }


  # Classic logging_config – CloudFront writes logs directly to S3
  logging_config {
    bucket = "${aws_s3_bucket.cf_logs1.bucket}.s3.amazonaws.com"
    prefix = "cloudfront/"
    include_cookies = false
  }

  
}

# Explanation: This is Chewbacca’s secret handshake — if the header isn’t present, you don’t get in.
resource "random_password" "origin_header_value01" {
  length  = 32
  special = false
}


# Data source (optional but convenient)
# from perplexity
data "aws_cloudfront_cache_policy" "use_origin_cache" {
  name = "UseOriginCacheControlHeaders"
}
