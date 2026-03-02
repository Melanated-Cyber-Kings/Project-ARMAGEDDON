#needed for cloudwatch alarm
output arn_suffix {
    value = aws_lb.alb02.arn_suffix
}

#needed for zone53
output "lb_dns_name" {
  value = aws_lb.alb02.dns_name
}

#needed for zone53
output "zone_id" {
value = aws_lb.alb02.zone_id
}

#needed for cloudfront
output "waf_arn"{
  value = aws_wafv2_web_acl.waf02[0].arn
}