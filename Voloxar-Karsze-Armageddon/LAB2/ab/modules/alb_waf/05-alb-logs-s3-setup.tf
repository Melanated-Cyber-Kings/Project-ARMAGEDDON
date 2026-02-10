#creates the bucket
resource "aws_s3_bucket" "alb_logs_bucket" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = lower("${var.alb_access_logs_bucket_name}-${var.env_prefix}-alb-logs-${var.project}")
  force_destroy               = true

  tags = {
    Name        = "${var.env_prefix}-alb-logs-bucket"
    Environment = var.env_prefix
  }
}

#locks it down, no public acccess
resource "aws_s3_bucket_public_access_block" "alb_logs_pab" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket                  = aws_s3_bucket.alb_logs_bucket[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#make it ours for sure
resource "aws_s3_bucket_ownership_controls" "alb_logs_owner" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.alb_logs_bucket[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#grab some info about basic alb setups
data "aws_elb_service_account" "alb" {}


#data writing policy
data "aws_iam_policy_document" "alb_logs_bucket_policy" {
  statement {
    sid = "AWSALBWriteAccess"

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.alb.arn]
    }

    actions = [
      "s3:PutObject"
    ]

    # If you use a prefix, include it here, e.g. "...:bucket-name/prefix/*"
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.alb_logs_bucket[0].bucket}/${var.alb_access_logs_prefix}/*"
    ]
  }
}

#connect the policy and the bucket together
resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_logs_bucket[0].id
  policy = data.aws_iam_policy_document.alb_logs_bucket_policy.json
}