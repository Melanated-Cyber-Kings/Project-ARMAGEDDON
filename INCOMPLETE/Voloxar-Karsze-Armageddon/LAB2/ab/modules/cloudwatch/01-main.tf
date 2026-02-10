# 1. SNS Topic for Alerts
resource "aws_sns_topic" "db_incidents" {
  name = "lab-db-incidents"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.db_incidents.arn
  protocol  = "email"
  endpoint  = var.alert_email 
}

# 2. CloudWatch Log Group (if not already exists)
resource "aws_cloudwatch_log_group" "app_logs" {
  name = "/aws/ec2/lab-rds-app"
  retention_in_days = 7
}

# 3. CloudWatch Alarm (simplified - we'll create metric filter via CLI later)
resource "aws_cloudwatch_metric_alarm" "db_failure" {
  alarm_name          = "lab-db-connection-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DBConnectionErrors"
  namespace           = "Lab/RDSApp"
  period              = "300"
  statistic           = "Sum"
  threshold           = "3"
  alarm_actions       = [aws_sns_topic.db_incidents.arn]
  ok_actions          = [aws_sns_topic.db_incidents.arn]
  
  # We'll add dimensions after creating the metric filter
  dimensions = {
    LogGroupName = aws_cloudwatch_log_group.app_logs.name
  }
  
  tags = var.tags
}

resource "aws_cloudwatch_log_metric_filter" "db_errors" {
  name           = "DBConnectionErrors"
  #pattern        = "CRITICAL"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.app_logs.name

  metric_transformation {
    name      = "DBConnectionErrors"
    namespace = "Lab/RDSApp"
    value     = "1"
  }
}


###bonus stuff###

#enable email message if alb breaks
resource "aws_sns_topic" "alb_incidents" {
  name = "lab-alb-incidents"
}

resource "aws_sns_topic_subscription" "alb_email" {
  topic_arn = aws_sns_topic.alb_incidents.arn
  protocol  = "email"
  endpoint  = var.alert_email 
}



############################################
# CloudWatch Alarm: ALB 5xx -> SNS
############################################

# Explanation: When the ALB starts throwing 5xx, that’s the Falcon coughing — page the on-call Wookiee.
resource "aws_cloudwatch_metric_alarm" "alb_5xx_alarm01" {
  alarm_name          = "${var.project}-alb-5xx-alarm01"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alb_5xx_evaluation_periods
  threshold           = var.alb_5xx_threshold
  period              = var.alb_5xx_period_seconds
  statistic           = "Sum"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  dimensions = {
    LoadBalancer = var.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alb_incidents.arn]

  tags = {
    Name = "${var.project}-alb-5xx-alarm01"
  }
}

############################################
# CloudWatch Dashboard (Skeleton)
############################################

# Explanation: Dashboards are your cockpit HUD — Chewbacca wants dials, not vibes.
resource "aws_cloudwatch_dashboard" "ALBalarm_dashboard01" {
  dashboard_name = "${var.project}-dashboard01"

  # TODO: students can expand widgets; this is a minimal workable skeleton
  dashboard_body = jsonencode({
    widgets = [
      {
        type  = "metric"
        x     = 0
        y     = 0
        width = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.arn_suffix ],
            [ ".", "HTTPCode_ELB_5XX_Count", ".", var.arn_suffix ]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "Chewbacca ALB: Requests + 5XX"
        }
      },
      {
        type  = "metric"
        x     = 12
        y     = 0
        width = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.arn_suffix ]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "Chewbacca ALB: Target Response Time"
        }
      }
    ]
  })
}