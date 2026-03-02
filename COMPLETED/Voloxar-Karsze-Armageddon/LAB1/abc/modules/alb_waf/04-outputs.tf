#needed for cloudwatch alarm
output arn_suffix {
    value = aws_lb.alb01.arn_suffix
}

#needed for zone53
output "lb_dns_name" {
  value = aws_lb.alb01.dns_name
}

#needed for zone53
output "zone_id" {
value = aws_lb.alb01.zone_id
}