####LAB2
# Explanation: The shield generator moves to the edge — CloudFront WAF blocks nonsense before it hits your VPC.
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

resource "aws_wafv2_web_acl" "shinjuku_cf_waf01" {
    provider = aws.virginia
    name  = "${var.env_prefix}-${var.account_id}-cf-waf01"
    scope = "CLOUDFRONT"

  default_action { 
    allow {} 
    }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.env_prefix}-${var.account_id}-cf-waf01"
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
      metric_name                = "${var.env_prefix}-${var.account_id}-cf-waf-common"
      sampled_requests_enabled   = true
    }
  }
}

##################################################
### Bonus E
# Explanation: WAF logs in CloudWatch are your “blaster-cam footage”—fast search, fast triage, fast truth.
resource "aws_cloudwatch_log_group" "shinjuku_waf_log_group01" {
  count = var.waf_log_destination == "cloudwatch" ? 1 : 0

  # NOTE: AWS requires WAF log destination names start with aws-waf-logs- (students must not rename this).
  name              = "aws-waf-logs-${var.env_prefix}-${var.account_id}-webacl01"
  retention_in_days = var.waf_log_retention_days

  tags = {
    Name = "${var.env_prefix}-waf-log-group01"
  }
}

# resource "aws_wafv2_web_acl_association" "shinjuku_waf_assoc01" {
#   provider = aws.virginia
# #  count = var.enable_waf ? 1 : 0

#   resource_arn = aws_cloudfront_distribution.shinjuku_cf01.arn
#   web_acl_arn  = aws_wafv2_web_acl.shinjuku_cf_waf01.arn
# }

# Explanation: This wire connects the shield generator to the black box—WAF -> CloudWatch Logs.
# resource "aws_wafv2_web_acl_logging_configuration" "shinjuku_waf_logging01" {
#   provider = aws.virginia
# #  count = var.enable_waf && var.waf_log_destination == "cloudwatch" ? 1 : 0

#   resource_arn = aws_wafv2_web_acl.shinjuku_cf_waf01.arn
#   log_destination_configs = [
#     aws_cloudwatch_log_group.shinjuku_waf_log_group01[0].arn
#   ]

#   # TODO: Students can add redacted_fields (authorization headers, cookies, etc.) as a stretch goal.
#   redacted_fields {
#     single_header {
#       name = "authorization"
#     }
#   }

#   redacted_fields {
#     single_header {
#       name = "cookie"
#     }
#   }

#   #depends_on = [aws_wafv2_web_acl.shinjuku_cf_waf01]
# }