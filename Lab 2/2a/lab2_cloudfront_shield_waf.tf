resource "aws_wafv2_web_acl" "chewbacca_cf_waf01" {
  provider = aws.us-east-1

  name  = "chewbacca-cf-waf01"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "chewbacca-cf-waf-common"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "chewbacca-cf-waf01"
    sampled_requests_enabled   = true
  }
}
