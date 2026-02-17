resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = var.retention_days
}

resource "aws_cloudwatch_log_metric_filter" "this" {
  name           = "${var.name_prefix}-filter"
  pattern        = var.filter_pattern
  log_group_name = aws_cloudwatch_log_group.this.name

  metric_transformation {
    name      = var.metric_name
    namespace = var.metric_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name          = "${var.name_prefix}-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = var.metric_name
  namespace           = var.metric_namespace
  period              = 60
  statistic           = "Sum"
  threshold           = var.threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
}