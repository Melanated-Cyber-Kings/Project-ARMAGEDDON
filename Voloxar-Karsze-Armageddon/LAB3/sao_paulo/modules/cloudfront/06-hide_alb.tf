# Explanation: DNS now points to CloudFront — nobody should ever see the ALB again.
resource "aws_route53_record" "apex_to_ccf01" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.ccf01.domain_name
    zone_id                = aws_cloudfront_distribution.ccf01.hosted_zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [aws_cloudfront_distribution.ccf01.domain_name]
  }
}

# Explanation: app.chewbacca-growl.com also points to CloudFront — same doorway, different sign.
resource "aws_route53_record" "app_to_ccf01" {
  zone_id = var.zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.ccf01.domain_name
    zone_id                = aws_cloudfront_distribution.ccf01.hosted_zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [aws_cloudfront_distribution.ccf01.domain_name]
  }
}