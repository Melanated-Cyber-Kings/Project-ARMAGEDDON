###############################################################################
# waf.tf
# Module: ingress (Lab-1C Bonus C)
###############################################################################

###############################################################################
# WAF WebACL + Association (ALB)
###############################################################################

resource "aws_wafv2_web_acl" "alb_waf" {
  name  = "${local.name_prefix}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
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
      metric_name                = "${local.name_prefix}-waf-common"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "alb_waf_assoc" {
  resource_arn = aws_lb.app_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.alb_waf.arn
}

###############################################################################
# CloudWatch Alarm: ALB 5xx -> SNS (SNS mandatory)
###############################################################################

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.name_prefix}-alb-5xx"
  alarm_description   = "ALB 5xx spike alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alb_5xx_evaluation_periods
  period              = var.alb_5xx_period_seconds
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  treat_missing_data  = "missing"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  dimensions = {
    LoadBalancer = aws_lb.app_alb.arn_suffix
  }

  alarm_actions = [var.alarm_action_topic_arn]
  ok_actions    = [var.alarm_action_topic_arn]
}

###############################################################################
# CloudWatch Dashboard (ALB)
###############################################################################

resource "aws_cloudwatch_dashboard" "alb_dashboard" {
  dashboard_name = "${local.name_prefix}-alb-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          region = var.region
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.app_alb.arn_suffix, { "stat" : "Sum" }],
            [".", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.app_alb.arn_suffix, { "stat" : "Sum" }]
          ]
          period      = 300
          stat        = "Sum"
          title       = "ALB Requests + ELB 5xx"
          annotations = {}
        }
      }
    ]
  })
}

###############################################################################
# WAF Logging (CloudWatch Logs)
###############################################################################
# AWS requires CloudWatch log group name to begin with:
#   aws-waf-logs-
###############################################################################

resource "aws_cloudwatch_log_group" "waf_logs" {
  count             = var.waf_log_destination == "cloudwatch" ? 1 : 0
  name              = "aws-waf-logs-${var.env_prefix}-webacl"
  retention_in_days = var.waf_log_retention_days
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.waf_log_destination == "cloudwatch" ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.alb_waf.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs[0].arn]

  depends_on = [aws_cloudwatch_log_group.waf_logs]
}
