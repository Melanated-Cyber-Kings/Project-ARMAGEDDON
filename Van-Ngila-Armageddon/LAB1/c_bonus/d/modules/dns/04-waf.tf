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