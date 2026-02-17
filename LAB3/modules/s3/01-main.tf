terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_elb_service_account" "main" {}

# 1. The Bucket
resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = merge({ Name = var.bucket_name }, var.tags)
}

# 2. The Ownership Controls
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# 3. The Public Access Block (Must allow ACLs for logging)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = false # Set to false to allow the logging ACL
  block_public_policy     = true
  ignore_public_acls      = false # Set to false to allow the logging ACL
  restrict_public_buckets = true
}

# 4. The ACL Grant (Must wait for Ownership and Public Access Block)
resource "aws_s3_bucket_acl" "log_delivery" {
  bucket = aws_s3_bucket.this.id
  acl    = "log-delivery-write"

  
  depends_on = [
    aws_s3_bucket_ownership_controls.this,
    aws_s3_bucket_public_access_block.this,
  ]
}


resource "aws_s3_bucket_policy" "alb_logging_policy" {
  bucket = aws_s3_bucket.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn 
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.this.arn}/alb-logs/AWSLogs/${var.account_id}/*"
      }
    ]
  })
}
