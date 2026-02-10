output "web_acl_arn" {
  description = "The ARN of the Global WAF for CloudFront association"
  value       = aws_wafv2_web_acl.this.arn
}