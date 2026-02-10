output "shinjuku_cf01_domain_name" {
  value = aws_cloudfront_distribution.shinjuku_cf01.domain_name
}

output "shinjuku_cf01_hosted_zone_id" {
  value = aws_cloudfront_distribution.shinjuku_cf01.hosted_zone_id
}

output "shinjuku_origin_header_value01_result" {
  value = random_password.shinjuku_origin_header_value01.result
}

output "shinjuku_waf_cw_log_group_name" {
  value = var.waf_log_destination == "cloudwatch" ? aws_cloudwatch_log_group.shinjuku_waf_log_group01[0].name : null
}

output "waf_arn" {
  value = aws_wafv2_web_acl.shinjuku_cf_waf01.arn
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.shinjuku_cf01.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.shinjuku_cf01.domain_name
}

output "origin_header_value" {
  value     = random_password.shinjuku_origin_header_value01.result
  sensitive = true
}