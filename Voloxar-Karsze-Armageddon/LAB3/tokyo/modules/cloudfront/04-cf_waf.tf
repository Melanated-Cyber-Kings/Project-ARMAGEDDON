#naming conflicts got on my nerves
resource "random_string" "short_string" {
  length  = 5
  special = false
  upper   = false
  lower   = true
 
}


resource "aws_wafv2_web_acl" "cf_waf01" {
  name  = "${var.project}_cf_waf01_${random_string.short_string.result}"
  scope = "CLOUDFRONT"
default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-cf-waf01"
    sampled_requests_enabled   = true
  }

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
      metric_name                = "${var.project}-cf-waf-common"
      sampled_requests_enabled   = true
    }
  }
}

