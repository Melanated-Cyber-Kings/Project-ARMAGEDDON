# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "test-alarm-sum"
resource "aws_cloudwatch_metric_alarm" "test_alarm_sum" {
  actions_enabled     = true
  alarm_actions       = ["arn:aws:sns:us-east-1:420228061920:armageddon-class-vii-db-incidents"]
  alarm_description   = "RDS connection Error"
  alarm_name          = "test-alarm-sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = 2
  dimensions = {
    DBInstanceIdentifier = "armageddon-class-vii-rds01"
  }
  evaluation_periods        = 2
  extended_statistic        = null
  insufficient_data_actions = []
  metric_name               = "DatabaseConnections"
  namespace                 = "AWS/RDS"
  ok_actions                = []
  period                    = 60
  region                    = "us-east-1"
  statistic                 = "Sum"
  tags                      = {}
  tags_all                  = {}
  threshold                 = 3
  threshold_metric_id       = null
  treat_missing_data        = "breaching"
  unit                      = null
}
