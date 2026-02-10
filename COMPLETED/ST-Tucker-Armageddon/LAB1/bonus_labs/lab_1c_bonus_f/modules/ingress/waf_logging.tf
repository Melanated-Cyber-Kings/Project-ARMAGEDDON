###############################################################################
# waf_logging.tf
# Module: ingress (Lab-1C)
# PURPOSE: WAF logging destination (one per WebACL)
# Destinations supported: cloudwatch | s3 | firehose
#
# Rubric constraints:
# - one destination per Web ACL
# - destination name must start with aws-waf-logs-
###############################################################################

# data "aws_caller_identity" "current" {}

locals {
  use_cw       = var.waf_log_destination == "cloudwatch"
  use_s3       = var.waf_log_destination == "s3"
  use_firehose = var.waf_log_destination == "firehose"

  # Required prefix per rubric
  waf_name_prefix = "aws-waf-logs-${var.env_prefix}"
}

###############################################################################
# Option 1: CloudWatch Logs destination
# NOTE: AWS requires log group name to start with: aws-waf-logs-
###############################################################################

resource "aws_cloudwatch_log_group" "waf_logs" {
  count             = local.use_cw ? 1 : 0
  name              = "${local.waf_name_prefix}-webacl"
  retention_in_days = var.waf_log_retention_days

  tags = merge(var.tags, {
    Name   = "${var.env_prefix}-waf-logs-cw"
    Module = "ingress"
  })
}

resource "aws_wafv2_web_acl_logging_configuration" "cw" {
  count = local.use_cw ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.alb_waf.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs[0].arn]

  depends_on = [aws_cloudwatch_log_group.waf_logs]
}

###############################################################################
# Option 2: S3 destination (direct)
# NOTE: bucket name must start with aws-waf-logs-
###############################################################################

resource "aws_s3_bucket" "waf_logs" {
  count = local.use_s3 ? 1 : 0

  # Must start with aws-waf-logs-
  bucket        = "${local.waf_name_prefix}-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.waf_logs_force_destroy

  tags = merge(var.tags, {
    Name   = "${var.env_prefix}-waf-logs-s3"
    Module = "ingress"
  })
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  count  = local.use_s3 ? 1 : 0
  bucket = aws_s3_bucket.waf_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "waf_logs" {
  count  = local.use_s3 ? 1 : 0
  bucket = aws_s3_bucket.waf_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "s3" {
  count = local.use_s3 ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.alb_waf.arn
  log_destination_configs = [aws_s3_bucket.waf_logs[0].arn]

  depends_on = [aws_s3_bucket.waf_logs]
}

###############################################################################
# Option 3: Firehose destination (WAF -> Firehose -> S3)
# NOTE: Firehose delivery stream name must start with aws-waf-logs-
###############################################################################

resource "aws_s3_bucket" "waf_firehose_dest" {
  count = local.use_firehose ? 1 : 0

  # Firehose destination bucket does not have to start with aws-waf-logs- per AWS,
  # but we keep naming consistent and neutral.
  bucket        = "${var.env_prefix}-waf-firehose-dest-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.waf_logs_force_destroy

  tags = merge(var.tags, {
    Name   = "${var.env_prefix}-waf-firehose-dest"
    Module = "ingress"
  })
}

resource "aws_s3_bucket_public_access_block" "waf_firehose_dest" {
  count  = local.use_firehose ? 1 : 0
  bucket = aws_s3_bucket.waf_firehose_dest[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "waf_firehose_dest" {
  count  = local.use_firehose ? 1 : 0
  bucket = aws_s3_bucket.waf_firehose_dest[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "firehose_assume" {
  count = local.use_firehose ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "waf_firehose_role" {
  count              = local.use_firehose ? 1 : 0
  name               = "${var.env_prefix}-waf-firehose-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume[0].json

  tags = merge(var.tags, { Module = "ingress" })
}

data "aws_iam_policy_document" "waf_firehose_policy" {
  count = local.use_firehose ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.waf_firehose_dest[0].arn,
      "${aws_s3_bucket.waf_firehose_dest[0].arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "waf_firehose_inline" {
  count  = local.use_firehose ? 1 : 0
  name   = "${var.env_prefix}-waf-firehose-policy"
  role   = aws_iam_role.waf_firehose_role[0].id
  policy = data.aws_iam_policy_document.waf_firehose_policy[0].json
}

resource "aws_kinesis_firehose_delivery_stream" "waf_logs" {
  count = local.use_firehose ? 1 : 0

  # Must start with aws-waf-logs-
  name        = "${local.waf_name_prefix}-firehose01"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.waf_firehose_role[0].arn
    bucket_arn = aws_s3_bucket.waf_firehose_dest[0].arn
    prefix     = "waf-logs/"

    buffering_interval = 60
    buffering_size     = 5
    compression_format = "GZIP"
  }

  tags = merge(var.tags, { Module = "ingress" })
}

resource "aws_wafv2_web_acl_logging_configuration" "firehose" {
  count = local.use_firehose ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.alb_waf.arn
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_logs[0].arn]

  depends_on = [aws_kinesis_firehose_delivery_stream.waf_logs]
}
