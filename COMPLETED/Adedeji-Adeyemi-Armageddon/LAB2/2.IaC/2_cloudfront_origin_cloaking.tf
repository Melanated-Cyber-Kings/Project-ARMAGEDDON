###########################################################
# 1. Data Sources, Secrets & Custom Policies
###########################################################
data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# Managed policy kept for the API/Default behavior only
data "aws_cloudfront_cache_policy" "no_cache" {
  name = "Managed-CachingDisabled"
}

resource "random_password" "origin_secret" {
  length  = 32
  special = false
}


###########################################################
# 2. ALB Security Group (The Moat)
###########################################################
resource "aws_vpc_security_group_ingress_rule" "alb_allow_cloudfront_only" {
  security_group_id = aws_security_group.chewbacca_alb_sg01.id
  description       = "Allow HTTPS only from CloudFront Managed Prefix List"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.id
}

###########################################################
# 3. ALB Listeners & Dynamic Header Rule
###########################################################
resource "aws_lb_listener" "chewbacca_https_listener01" {
  load_balancer_arn = aws_lb.chewbacca_alb01.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.chewbacca_acm_validation01_dns_bonus[0].certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied: Missing Origin Shield"
      status_code  = "403"
    }
  }
}

resource "aws_lb_listener_rule" "allow_cloudfront_header" {
  listener_arn = aws_lb_listener.chewbacca_https_listener01.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chewbacca_tg01.arn
  }
  condition {
    http_header {
      http_header_name = "X-Chewbacca-Growl"
      values           = [random_password.origin_secret.result] 
    }
  }
}

resource "aws_lb_listener" "chewbacca_http_listener01" {
  load_balancer_arn = aws_lb.chewbacca_alb01.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

###########################################################
# 4. CloudFront Distribution (The Secure Cloak)
###########################################################
resource "aws_cloudfront_distribution" "chewbacca_cf01" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront for Chewbacca Growl"
  web_acl_id      = aws_wafv2_web_acl.chewbacca_cf_waf01.arn
  aliases         = ["tritechsite.com", "app.tritechsite.com"]

  origin {
    domain_name = aws_lb.chewbacca_alb01.dns_name
    origin_id   = "chewbacca-alb-origin"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    custom_header {
      name  = "X-Chewbacca-Growl"
      value = random_password.origin_secret.result
    }
  }

  # Default behavior (Root /)
  default_cache_behavior {
    target_origin_id       = "chewbacca-alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.no_cache.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.chewbacca_orp_api01.id
  }

  # API Behavior
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "chewbacca-alb-origin"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.no_cache.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.chewbacca_orp_api01.id
    viewer_protocol_policy   = "redirect-to-https"
  }

  # Static Behavior (THE SPEED LANE)
  ordered_cache_behavior {
    path_pattern     = "/static/*"
    target_origin_id = "chewbacca-alb-origin"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]

    # Swapped to Custom Policies for Caching Success
    cache_policy_id            = aws_cloudfront_cache_policy.chewbacca_cache_static01.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.chewbacca_orp_static01.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.chewbacca_rsp_static01.id
    
    viewer_protocol_policy     = "redirect-to-https"
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.chewbacca_cf_cert_us_east_1.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

###########################################################
# 5. Certificates & Redirects
###########################################################
resource "aws_acm_certificate" "chewbacca_cf_cert_us_east_1" {
  provider          = aws.us_east_1
  domain_name       = "tritechsite.com"
  validation_method = "DNS"
  subject_alternative_names = ["app.tritechsite.com"]
  lifecycle { create_before_destroy = true }
}

resource "aws_route53_record" "cf_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.chewbacca_cf_cert_us_east_1.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.chewbacca_zone01[0].zone_id
}

resource "aws_acm_certificate_validation" "cf_cert_validate" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.chewbacca_cf_cert_us_east_1.arn
  validation_record_fqdns = [for record in aws_route53_record.cf_cert_validation : record.fqdn]
}

resource "aws_lb_listener_rule" "redirect_root_to_app" {
  listener_arn = aws_lb_listener.chewbacca_https_listener01.arn
  priority     = 5 
  action {
    type = "redirect"
    redirect {
      host        = "app.tritechsite.com"
      path        = "/#{path}"
      query       = "#{query}"
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  condition {
    host_header {
      values = ["tritechsite.com"]
    }
  }
}