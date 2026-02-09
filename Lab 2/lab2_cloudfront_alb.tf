# lab2_cloudfront_alb.tf
# CloudFront distribution in front of ALB

# ACM certificate in us-east-1 for CloudFront
resource "aws_acm_certificate" "chewbacca_cf_cert" {
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
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "chewbacca_cf01" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "chewbacca-cf01"

  origin {
    origin_id   = "chewbacca-alb-origin01"
    domain_name = data.aws_lb.existing_alb.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    # Secret header for origin cloaking
    custom_header {
      name  = "X-Chewbacca-Growl"
      value = "mdcYLQtpJJuDYqn0X0YvKqg37XDA2s9b"
    }
  }

  default_cache_behavior {
    target_origin_id       = "chewbacca-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Attach WAF
  web_acl_id = aws_wafv2_web_acl.chewbacca_cf_waf01.arn

  # Custom domains
  aliases = [
    var.domain_name,
    "${var.app_subdomain}.${var.domain_name}"
  ]

  # ACM certificate from us-east-1
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.chewbacca_cf_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

