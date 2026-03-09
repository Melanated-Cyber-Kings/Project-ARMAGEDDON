###########################################################
# 1. Point the Apex Domain (tritechsite.com) to CloudFront
###########################################################
resource "aws_route53_record" "apex_to_cloudfront" {
  zone_id = aws_route53_zone.chewbacca_zone01[0].zone_id
  name    = var.domain_name
  type    = "A"
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.chewbacca_cf01.domain_name
    zone_id                = aws_cloudfront_distribution.chewbacca_cf01.hosted_zone_id
    evaluate_target_health = false
  }
}

###########################################################
# 2. Point the App Subdomain (app.tritechsite.com) to CloudFront
###########################################################
resource "aws_route53_record" "app_to_cloudfront" {
  zone_id = aws_route53_zone.chewbacca_zone01[0].zone_id
  name    = "app.tritechsite.com"
  type    = "A"
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.chewbacca_cf01.domain_name
    zone_id                = aws_cloudfront_distribution.chewbacca_cf01.hosted_zone_id
    evaluate_target_health = false
  }
}