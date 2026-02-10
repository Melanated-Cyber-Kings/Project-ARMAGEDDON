############################################
# WAFv2 Web ACL (Basic managed rules)
############################################

# Explanation: WAF is the shield generator — it blocks the cheap blaster fire before it hits your ALB.
resource "aws_wafv2_web_acl" "waf01" {
  count = var.enable_waf ? 1 : 0

  name  = "${var.project}-waf01"
  scope = "REGIONAL"
  

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-waf01"
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
      metric_name                = "${var.project}-waf-common"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Name = "${var.project}-waf01"
  }
}

# Explanation: Attach the shield generator to the customs checkpoint — ALB is now protected.
resource "aws_wafv2_web_acl_association" "waf_assoc01" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_lb.alb01.arn
 
  web_acl_arn  = aws_wafv2_web_acl.waf01[0].arn
}
