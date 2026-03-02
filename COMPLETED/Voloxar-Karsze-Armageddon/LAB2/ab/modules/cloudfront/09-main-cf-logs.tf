data "aws_caller_identity" "current" {}

############################################
# S3 Bucket for CloudFront Logs
############################################

resource "aws_s3_bucket" "cf_logs1" {
  provider = aws.use1

  bucket = lower("cloudfront-logs-${var.project}-tokyo-${random_string.short_string.result}")
  force_destroy               = true

  tags = {
    Name = "${var.project}-tokyo-cloudfront-logs"
  }
}

############################################
# Block Public Access
############################################

resource "aws_s3_bucket_public_access_block" "cf_logs1" {
  provider = aws.use1
  bucket   = aws_s3_bucket.cf_logs1.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################################
# Disable ACLs (Modern Best Practice)
############################################

resource "aws_s3_bucket_ownership_controls" "cf_logs1" {
  provider = aws.use1
  bucket   = aws_s3_bucket.cf_logs1.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# ############################################
# Allow CloudFront to Write Logs
############################################

resource "aws_s3_bucket_policy" "cf_logs_policy" {
  provider = aws.use1
  bucket   = aws_s3_bucket.cf_logs1.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontLogs"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cf_logs1.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}



resource "aws_s3_bucket_acl" "cf_logs1_reset" {
  provider = aws.use1
  bucket   = aws_s3_bucket.cf_logs1.id
  acl      = "log-delivery-write"
}
