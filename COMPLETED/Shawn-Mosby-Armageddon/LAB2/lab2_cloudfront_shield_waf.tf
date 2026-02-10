###########################################################
# 1. Global WAF for CloudFront (Edge Protection)
###########################################################
resource "aws_wafv2_web_acl" "chewbacca_cf_waf01" {
  provider = aws.us_east_1 # CRITICAL: CloudFront WAFs must be in us-east-1
  name     = "chewbacca-cf-waf01"
  scope    = "CLOUDFRONT" # CRITICAL: Scope must be CLOUDFRONT

  default_action {
    allow {}
  }

  # Re-using the Managed Common Rule Set from Lab 1
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
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
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "chewbacca-cf-waf-main-metric"
    sampled_requests_enabled   = true
  }
}

###########################################################
# 2. Logging Configuration (Optional but Recommended)
###########################################################
# Note: WAF logs for CloudFront are also sent to CloudWatch, 
# but the Log Group must also be in us-east-1.