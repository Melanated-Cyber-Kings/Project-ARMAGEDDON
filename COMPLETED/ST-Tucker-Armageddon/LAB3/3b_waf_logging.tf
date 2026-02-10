# Create the WAF Web ACL in us-east-1
resource "aws_wafv2_web_acl" "medical_global_waf" {
  provider    = aws.us_east_1
  name        = "medical-global-waf"
  description = "Global WAF for Medical Vault PHI protection"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # This rule gives you the "Security Proof" for the audit
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
    metric_name                = "medical-global-waf-main-metric"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudwatch_log_group" "waf_log_group" {
  provider          = aws.us_east_1 # Ensure you have a provider for us-east-1
  name              = "aws-waf-logs-medical-vault"
  retention_in_days = 365 # Auditors usually want 1 year of security logs
}

resource "aws_wafv2_web_acl_logging_configuration" "medical_waf_logging" {
  provider                = aws.us_east_1
  log_destination_configs = [aws_cloudwatch_log_group.waf_log_group.arn]
  resource_arn            = aws_wafv2_web_acl.medical_global_waf.arn # Replace with your ACL resource name

  # Redact sensitive data if necessary for APPI
  logging_filter {
    default_behavior = "KEEP"
    filter {
      behavior = "KEEP"
      condition {
        action_condition {
          action = "BLOCK" # Prioritize logging blocked attacks as evidence
        }
      }
      requirement = "MEETS_ANY"
    }
  }
}