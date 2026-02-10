resource "aws_s3_bucket" "alb_logs_bucket" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = var.bucket_name != "" ? var.bucket_name : "${var.env_prefix}-alb-logs-${var.account_id}"

  tags = {
    Name        = "${var.env_prefix}-alb-logs-bucket"
    Environment = var.env_prefix
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs_pab" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket                  = aws_s3_bucket.alb_logs_bucket[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "alb_logs_owner" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.alb_logs_bucket[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "alb_logs_policy" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.alb_logs_bucket[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.alb_logs_bucket[0].arn,
          "${aws_s3_bucket.alb_logs_bucket[0].arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid    = "AllowELBPutObject"
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs_bucket[0].arn}/${var.alb_access_logs_prefix}/AWSLogs/${var.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl": "bucket-owner-full-control"
          },
          "ArnLike": {
          "aws:SourceArn": "arn:aws:elasticloadbalancing:ap-northeast-1:031857855861:loadbalancer/app/armageddon-lab-1c-alb-public/*"
          }
        }
      },
      {
        Sid    = "AllowELBListBucket"
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action = "s3:ListBucket"
        Resource = aws_s3_bucket.alb_logs_bucket[0].arn
      }
    ]
  })
}
