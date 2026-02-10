# Explanation: WAF logs in CloudWatch are your “blaster-cam footage”—fast search, fast triage, fast truth.
resource "aws_cloudwatch_log_group" "waf_log_group01" {
  count = var.waf_log_destination == "cloudwatch" ? 1 : 0

  # NOTE: AWS requires WAF log destination names start with aws-waf-logs- (students must not rename this).
  name              = "aws-waf-logs-${var.env_prefix}-webacl01"
  retention_in_days = var.waf_log_retention_days

  tags = {
    Name = "${var.env_prefix}-waf-log-group01"
  }
}

# Explanation: This wire connects the shield generator to the black box—WAF -> CloudWatch Logs.
resource "aws_wafv2_web_acl_logging_configuration" "waf_logging01" {
  count = var.enable_waf && var.waf_log_destination == "cloudwatch" ? 1 : 0

  resource_arn = aws_wafv2_web_acl.waf01[0].arn
  depends_on = [aws_wafv2_web_acl.waf01]
  
  log_destination_configs = [
    aws_cloudwatch_log_group.waf_log_group01[0].arn
  ]

  # TODO: Students can add redacted_fields (authorization headers, cookies, etc.) as a stretch goal.
  #VK: Want to see what's recorded first
  #   redacted_fields {
  #     single_header {
  #       name = "user-agent"
  #     }
  #   }

 
}