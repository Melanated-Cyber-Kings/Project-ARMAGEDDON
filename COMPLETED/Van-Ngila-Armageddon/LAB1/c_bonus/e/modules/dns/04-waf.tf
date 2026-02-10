resource "aws_wafv2_web_acl" "chewbacca_waf01" {
  count = var.enable_waf ? 1 : 0

  name  = "${var.env_prefix}-waf01"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.env_prefix}-waf01"
    sampled_requests_enabled   = true
  }

  # Explanation: AWS managed rules are like hiring Rebel commandos — they’ve seen every trick.
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
      metric_name                = "${var.env_prefix}-waf-common"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Name = "${var.env_prefix}-waf01"
  }
}

resource "aws_wafv2_web_acl_association" "chewbacca_waf_assoc01" {
  count = var.enable_waf ? 1 : 0

  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.chewbacca_waf01[0].arn
}

##################################################
### Bonus E
# Explanation: WAF logs in CloudWatch are your “blaster-cam footage”—fast search, fast triage, fast truth.
resource "aws_cloudwatch_log_group" "chewbacca_waf_log_group01" {
  count = var.waf_log_destination == "cloudwatch" ? 1 : 0

  # NOTE: AWS requires WAF log destination names start with aws-waf-logs- (students must not rename this).
  name              = "aws-waf-logs-${var.env_prefix}-webacl01"
  retention_in_days = var.waf_log_retention_days

  tags = {
    Name = "${var.env_prefix}-waf-log-group01"
  }
}

# Explanation: This wire connects the shield generator to the black box—WAF -> CloudWatch Logs.
resource "aws_wafv2_web_acl_logging_configuration" "chewbacca_waf_logging01" {
  count = var.enable_waf && var.waf_log_destination == "cloudwatch" ? 1 : 0

  resource_arn = aws_wafv2_web_acl.chewbacca_waf01[0].arn
  log_destination_configs = [
    aws_cloudwatch_log_group.chewbacca_waf_log_group01[0].arn
  ]

  # TODO: Students can add redacted_fields (authorization headers, cookies, etc.) as a stretch goal.
  redacted_fields {
    single_header {
      name = "user-agent"
    }
  }

  depends_on = [aws_wafv2_web_acl.chewbacca_waf01]
}