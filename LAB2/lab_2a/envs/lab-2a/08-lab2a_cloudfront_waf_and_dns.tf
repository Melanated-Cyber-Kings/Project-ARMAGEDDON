###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# LAB:   LAB-2A
# COMPONENT: CloudFront + WAF + Route53
#
# PURPOSE
# - Put CloudFront in front of the ALB
# - Attach WAFv2 (scope CLOUDFRONT)
# - Point apex + app DNS to CloudFront
###############################################################################

###############################################################################
# WAFv2 for CloudFront (global scope)
###############################################################################
resource "aws_wafv2_web_acl" "cf_waf" {
  provider = aws.us_east_1

  name  = "${local.name_prefix}-cf-waf01"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-cf-waf01"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-cf-waf-common"
      sampled_requests_enabled   = true
    }
  }
}

###############################################################################
# CloudFront distribution → ALB custom origin
###############################################################################
resource "aws_cloudfront_distribution" "cf" {
  provider = aws.us_east_1

  enabled         = true
  is_ipv6_enabled = true
  comment         = "${local.name_prefix}-cf01"

  aliases = [
    var.domain_name,
    "${var.app_subdomain}.${var.domain_name}",
  ]

  origin {
    origin_id   = "${local.name_prefix}-alb-origin01"
    domain_name = aws_lb.app_alb.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    # CloudFront adds the secret; ALB only forwards when it matches.
    custom_header {
      name  = var.origin_header_name
      value = random_password.origin_header_value.result
    }
  }

  default_cache_behavior {
    target_origin_id       = "${local.name_prefix}-alb-origin01"
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
  }

  # Attach WAF at the edge
  web_acl_id = aws_wafv2_web_acl.cf_waf.arn

  viewer_certificate {
    acm_certificate_arn      = var.enable_route53 ? aws_acm_certificate_validation.edge_cert[0].certificate_arn : aws_acm_certificate.edge_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_root_object = ""

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-cf01"
  })
}

###############################################################################
# Route53: apex + app → CloudFront (ALIAS)
# - allow_overwrite prevents “already exists” loops.
###############################################################################
resource "aws_route53_record" "apex_to_cloudfront" {
  count = var.enable_route53 ? 1 : 0

  zone_id         = var.route53_zone_id
  name            = var.domain_name
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.cf.domain_name
    zone_id                = aws_cloudfront_distribution.cf.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "app_to_cloudfront" {
  count = var.enable_route53 ? 1 : 0

  zone_id         = var.route53_zone_id
  name            = "${var.app_subdomain}.${var.domain_name}"
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.cf.domain_name
    zone_id                = aws_cloudfront_distribution.cf.hosted_zone_id
    evaluate_target_health = false
  }
}


