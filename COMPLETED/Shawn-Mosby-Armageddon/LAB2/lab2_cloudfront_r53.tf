###########################################################
# 1. Point the Apex Domain (lewsdomain.com) to CloudFront
###########################################################
resource "aws_route53_record" "apex_to_cloudfront" {
  zone_id = aws_route53_zone.chewbacca_zone01[0].zone_id
  name    = "lewsdomain.com"
  type    = "A"
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.chewbacca_cf01.domain_name
    zone_id                = aws_cloudfront_distribution.chewbacca_cf01.hosted_zone_id
    evaluate_target_health = false
  }
}

###########################################################
# 2. Point the App Subdomain (app.lewsdomain.com) to CloudFront
###########################################################
resource "aws_route53_record" "app_to_cloudfront" {
  zone_id = aws_route53_zone.chewbacca_zone01[0].zone_id
  name    = "app.lewsdomain.com"
  type    = "A"
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.chewbacca_cf01.domain_name
    zone_id                = aws_cloudfront_distribution.chewbacca_cf01.hosted_zone_id
    evaluate_target_health = false
  }
}