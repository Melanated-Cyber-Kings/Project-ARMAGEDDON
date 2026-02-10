# lab2_cloudfront_alb.tf
# CloudFront distribution in front of ALB

# ACM certificate in us-east-1 for CloudFront
/*resource "aws_acm_certificate" "chewbacca_cf_cert" {
  provider = aws.us-east-1

  domain_name       = var.domain_name # givenchyops.com
  validation_method = "DNS"

  subject_alternative_names = [
    "${var.app_subdomain}.${var.domain_name}" # app.givenchyops.com
  ]

  tags = {
    Name = "chewbacca-cf-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}*/

# CloudFront distribution
resource "aws_cloudfront_distribution" "chewbacca_cf01" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "chewbacca-cf01"

  origin {
    origin_id   = "chewbacca-alb-origin01"
    domain_name = "alb-app.givenchyops.com" 

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout      = 60  # Matches "Response timeout"
      origin_keepalive_timeout = 60  # Matches "Keep-alive timeout"
    }

    custom_header {
      name  = "X-Chewbacca-Growl"  # ✅ Allowed header
      value = var.custom_header_value
      
        # ADD THIS - Force Host header for SNI
    /*custom_header {
      name  = "Host"
      value = "app.givenchyops.com"*/
  }

    # Secret header for origin cloaking
    /*custom_header {
      name  = "X-Chewbacca-Growl"
      value = var.custom_header_value
    }*/
  }

  default_cache_behavior {
    target_origin_id       = "chewbacca-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    # Lab 2B: Replace forwarded_values with cache/request policies
    cache_policy_id          = aws_cloudfront_cache_policy.chewbacca_cache_api_disabled01.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.chewbacca_orp_default01.id #"f65e65f8-d714-40dc-9b19-4b71a99efbf6"
    compress = true
  }

  # =============================================
  # Lab 2B: CACHE BEHAVIORS
  # =============================================
  ordered_cache_behavior {
    path_pattern     = "/static/*"
    target_origin_id = "chewbacca-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    # Static content: Aggressive caching
    cache_policy_id            = aws_cloudfront_cache_policy.chewbacca_cache_static01.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.chewbacca_orp_static01.id   #"f65e65f8-d714-40dc-9b19-4b71a99efbf6"   
    #response_headers_policy_id = aws_cloudfront_response_headers_policy.chewbacca_response_headers01.id

    compress = true
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "chewbacca-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    # API: No caching (safe default)
    cache_policy_id          = aws_cloudfront_cache_policy.chewbacca_cache_api_disabled01.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.chewbacca_orp_api01.id  #"f65e65f8-d714-40dc-9b19-4b71a99efbf6"   #aws_cloudfront_origin_request_policy.chewbacca_orp_api01.id

    compress = true
  }
  
  # Attach WAF
   #web_acl_id = aws_wafv2_web_acl.chewbacca_cf_waf01.arn

  # Custom domains
  aliases = [
    var.domain_name,
    "${var.app_subdomain}.${var.domain_name}"
  ]

  # ACM certificate from us-east-1
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}