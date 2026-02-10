############################################
# Option 1: CloudWatch Logs destination
############################################

# Explanation: WAF logs in CloudWatch are your “blaster-cam footage”—fast search, fast triage, fast truth.
resource "aws_cloudwatch_log_group" "chewbacca_waf_log_group01" {
  count = var.waf_log_destination == "cloudwatch" ? 1 : 0
  provider = aws.us_east_1
  # NOTE: AWS requires WAF log destination names start with aws-waf-logs- (students must not rename this).
  name              = "aws-waf-logs-lew-webacl01"
  retention_in_days = var.waf_log_retention_days

  tags = {
    Name = "${var.project_name}-waf-log-group01"
  }
}


# Explanation: WAF is a separate droid—CloudWatch needs to see its ID card before letting it write logs.
resource "aws_cloudwatch_log_resource_policy" "chewbacca_waf_cw_policy01" {
  count = var.waf_log_destination == "cloudwatch" ? 1 : 0

  policy_name = "${var.project_name}-waf-cw-policy01"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowWAFToLog"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.chewbacca_waf_log_group01[0].arn}:*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.chewbacca_self01.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.chewbacca_self01.account_id}:*"
          }
        }
      }
    ]
  })
}
