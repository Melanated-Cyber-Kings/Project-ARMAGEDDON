############################################
# Bonus B - WAF Logging
############################################

############################################
# Option 1: CloudWatch Logs destination
############################################

resource "aws_cloudwatch_log_group" "lab1_waf_log_group01" {
  count = var.waf_log_destination == "cloudwatch" ? 1 : 0

  # AWS requirement: name must start with aws-waf-logs-
  name              = "aws-waf-logs-${var.project_name}-webacl01"
  retention_in_days = var.waf_log_retention_days

  tags = {
    Name = "${var.project_name}-waf-log-group01"
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "lab1_waf_logging01" {
  count = var.enable_waf && var.waf_log_destination == "cloudwatch" ? 1 : 0

  resource_arn = aws_wafv2_web_acl.lab1_waf01[0].arn
  log_destination_configs = [
    aws_cloudwatch_log_group.lab1_waf_log_group01[0].arn
  ]

  depends_on = [aws_wafv2_web_acl.lab1_waf01]
}

############################################
# # Option 2: S3 destination (direct)
# ############################################

# resource "aws_s3_bucket" "lab1_waf_logs_bucket01" {
#   count = var.waf_log_destination == "s3" ? 1 : 0

#   # AWS requirement: name must start with aws-waf-logs-
#   bucket = "aws-waf-logs-${var.project_name}-${data.aws_caller_identity.current.account_id}"

#   tags = {
#     Name = "${var.project_name}-waf-logs-bucket01"
#   }
# }

# resource "aws_s3_bucket_public_access_block" "lab1_waf_logs_pab01" {
#   count = var.waf_log_destination == "s3" ? 1 : 0

#   bucket                  = aws_s3_bucket.lab1_waf_logs_bucket01[0].id
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# resource "aws_wafv2_web_acl_logging_configuration" "lab1_waf_logging_s3_01" {
#   count = var.enable_waf && var.waf_log_destination == "s3" ? 1 : 0

#   resource_arn = aws_wafv2_web_acl.lab1_waf01[0].arn
#   log_destination_configs = [
#     aws_s3_bucket.lab1_waf_logs_bucket01[0].arn
#   ]

#   depends_on = [aws_wafv2_web_acl.lab1_waf01]
# }

# # ############################################
# # # Option 3: Firehose destination
# # ############################################

# # resource "aws_s3_bucket" "lab1_firehose_waf_dest_bucket01" {
# #   count = var.waf_log_destination == "firehose" ? 1 : 0

# #   bucket = "${var.project_name}-waf-firehose-dest-${data.aws_caller_identity.current.account_id}"

# #   tags = {
# #     Name = "${var.project_name}-waf-firehose-dest-bucket01"
# #   }
# # }

# # resource "aws_iam_role" "lab1_firehose_role01" {
# #   count = var.waf_log_destination == "firehose" ? 1 : 0
# #   name  = "${var.project_name}-firehose-role01"

# #   assume_role_policy = jsonencode({
# #     Version = "2012-10-17"
# #     Statement = [{
# #       Effect = "Allow"
# #       Principal = { Service = "firehose.amazonaws.com" }
# #       Action = "sts:AssumeRole"
# #     }]
# #   })
# # }

# # resource "aws_iam_role_policy" "lab1_firehose_policy01" {
# #   count = var.waf_log_destination == "firehose" ? 1 : 0
# #   name  = "${var.project_name}-firehose-policy01"
# #   role  = aws_iam_role.lab1_firehose_role01[0].id

# #   policy = jsonencode({
# #     Version = "2012-10-17"
# #     Statement = [
# #       {
# #         Effect = "Allow"
# #         Action = [
# #           "s3:AbortMultipartUpload",
# #           "s3:GetBucketLocation",
# #           "s3:GetObject",
# #           "s3:ListBucket",
# #           "s3:ListBucketMultipartUploads",
# #           "s3:PutObject"
# #         ]
# #         Resource = [
# #           aws_s3_bucket.lab1_firehose_waf_dest_bucket01[0].arn,
# #           "${aws_s3_bucket.lab1_firehose_waf_dest_bucket01[0].arn}/*"
# #         ]
# #       }
# #     ]
# #   })
# # }

# # resource "aws_kinesis_firehose_delivery_stream" "lab1_waf_firehose01" {
# #   count       = var.waf_log_destination == "firehose" ? 1 : 0
# #   # AWS requirement: name must start with aws-waf-logs-
# #   name        = "aws-waf-logs-${var.project_name}-firehose01"
# #   destination = "extended_s3"

# #   extended_s3_configuration {
# #     role_arn   = aws_iam_role.lab1_firehose_role01[0].arn
# #     bucket_arn = aws_s3_bucket.lab1_firehose_waf_dest_bucket01[0].arn
# #     prefix     = "waf-logs/"
# #   }
# # }

# # resource "aws_wafv2_web_acl_logging_configuration" "lab1_waf_logging_firehose01" {
# #   count = var.enable_waf && var.waf_log_destination == "firehose" ? 1 : 0

# #   resource_arn = aws_wafv2_web_acl.lab1_waf01[0].arn
# #   log_destination_configs = [
# #     aws_kinesis_firehose_delivery_stream.lab1_waf_firehose01[0].arn
# #   ]

# #   depends_on = [aws_wafv2_web_acl.lab1_waf01]
# # }
