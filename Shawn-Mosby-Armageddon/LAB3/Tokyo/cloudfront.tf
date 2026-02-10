
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

resource "aws_cloudfront_distribution" "medical_global_dist" {
  # Tokyo Origin (Hub)
##############################Brimah Made changes here##############################
  web_acl_id = aws_wafv2_web_acl.medical_global_waf.arn
    
/*Changes here 
domaain_name = aws_lb.shinjuku_alb.dns_name
This uses *.elb.amazonaws.com 
But our ALB certificate is (or should be):
shinjuku-origin.example.com CloudFront validates the cert against the hostname it connects to.
These must match or the handshake fails.
*/
origin {
  domain_name = "shinjuku-origin.lewsdomain.com" 
  origin_id   = "shinjuku-origin"
  custom_header { #added for lab 3b. Tells CF to give a secret header to the ALBs
      name  = "X-Medical-Vault-Secret"
      value = "VaultSecret2026!-Compliance" # In production, use Secrets Manager
    }
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only" #Changes here 
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
#####################################################################################
  # São Paulo Origin (Spoke)

##############################Brimah Made changes here###############################


/*Changes here 
domain_name = "liberdade-origin.example.com"
This uses *.elb.amazonaws.com 
But our ALB certificate is (or should be):
shinjuku-origin.example.com CloudFront validates the cert against the hostname it connects to.
These must match or the handshake fails.
*/
  origin {
    domain_name = "liberdade-origin.lewsdomain.com"
    origin_id   = "liberdade-origin"
    custom_header { #added for lab 3b. Tells CF to give a secret header to the ALBs
      name  = "X-Medical-Vault-Secret"
      value = "VaultSecret2026!-Compliance" # In production, use Secrets Manager
    }
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  #####################################################################################
logging_config { #added for lab 3b
    include_cookies = false
    bucket          = aws_s3_bucket.audit_log_vault.bucket_domain_name
    prefix          = "Chwebacca-logs/"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # High-Availability Failover Group
  origin_group {
    origin_id = "medical-failover-group"
    failover_criteria {
      status_codes = [500, 502, 503, 504]
    }
    member { origin_id = "liberdade-origin" }
    member { origin_id = "shinjuku-origin" }
  }

  # Dynamic Medical Records (Strictly No Caching)
  ordered_cache_behavior {
    path_pattern     = "/records/*"
    target_origin_id = "medical-failover-group"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    # Managed-CachingDisabled
    cache_policy_id = data.aws_cloudfront_cache_policy.caching_disabled.id
    # Managed-AllViewer (Forwards all headers so the app knows it's Brazil vs Tokyo)
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id

    viewer_protocol_policy = "redirect-to-https"
  }
  ordered_cache_behavior {
    path_pattern     = "/records/save/*"
    target_origin_id = "shinjuku-origin"

    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
    viewer_protocol_policy   = "redirect-to-https"
  }
  # Default Static Assets (Optimized Caching)
  default_cache_behavior {
    target_origin_id = "shinjuku-origin"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    # Managed-CachingOptimized
    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}
