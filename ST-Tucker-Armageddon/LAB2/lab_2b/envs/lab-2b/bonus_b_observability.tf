###############################################################################
# Bonus B — ALB Observability
# - SNS alarm on ALB 5xx spikes (mandatory)
# - CloudWatch dashboard for ALB signals
###############################################################################

locals {
  # CloudWatch ALB metrics require the ARN suffix: app/<lb-name>/<id>
  bonus_b_alb_arn_suffix = element(
    split("loadbalancer/", aws_lb.app_alb.arn),
    1
  )
}

###############################################################################
# ALB 5XX Alarm -> SNS
###############################################################################

resource "aws_cloudwatch_metric_alarm" "bonus_b_alb_5xx" {
  alarm_name          = "${var.env_prefix}-alb-5xx"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  evaluation_periods = var.alb_5xx_evaluation_periods
  threshold          = var.alb_5xx_threshold
  period             = var.alb_5xx_period_seconds
  statistic          = "Sum"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  dimensions = {
    LoadBalancer = local.bonus_b_alb_arn_suffix
  }

  alarm_actions = [module.cloudwatch.sns_topic_arn]
  ok_actions    = [module.cloudwatch.sns_topic_arn]

  tags = var.tags
}

###############################################################################
# CloudWatch Dashboard for ALB
###############################################################################

resource "aws_cloudwatch_dashboard" "bonus_b_alb_dashboard" {
  dashboard_name = "${var.env_prefix}-alb-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.bonus_b_alb_arn_suffix],
            [".", "HTTPCode_ELB_5XX_Count", ".", local.bonus_b_alb_arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "ALB: Requests + 5XX"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.bonus_b_alb_arn_suffix]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "ALB: Target Response Time"
        }
      }
    ]
  })
}
