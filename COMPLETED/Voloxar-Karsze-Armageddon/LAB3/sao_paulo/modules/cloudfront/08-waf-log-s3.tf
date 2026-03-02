# provider "aws" {
#   region = "us-east-1" # cloudfront logging location
#   alias = "use1"
# }

# resource "aws_s3_bucket" "waf_logs" {
#   bucket = lower("aws-waf-logs-${var.project}-sao-paulo-${random_string.short_string.result}")
#   provider = aws.use1

#   force_destroy = true
# }

# resource "aws_s3_bucket_ownership_controls" "waf_logs" {
#   bucket = aws_s3_bucket.waf_logs.id
#   provider = aws.use1

#   rule {
#     object_ownership = "BucketOwnerPreferred"
#   }
# }

# resource "aws_s3_bucket_acl" "waf_logs" {
#   bucket = aws_s3_bucket.waf_logs.id
#   provider = aws.use1
#   acl    = "private"

#   depends_on = [aws_s3_bucket_ownership_controls.waf_logs]
# }

# resource "aws_wafv2_web_acl_logging_configuration" "cf_waf02_logging" {
#   resource_arn = aws_wafv2_web_acl.cf_waf02.arn
#   #provider = aws.tokyo


#   log_destination_configs = [
#     aws_s3_bucket.waf_logs.arn
#   ]

#   # Optional: redact sensitive fields from logs
#   # redacted_fields {
#   #   single_header {
#   #     name = "authorization"
#   #   }
#   # }
# }

provider "aws" {
  region = "us-east-1" # CloudWatch global location
  alias  = "use1"
}

# Create an S3 bucket to store the WAF logs
resource "aws_s3_bucket" "waf_logs" {
  bucket = lower("aws-waf-logs-${var.project}-sao-paulo-${random_string.short_string.result}")
  provider = aws.use1

  force_destroy = true
}

# Set ownership controls for the S3 bucket (bucket owner preferred)
resource "aws_s3_bucket_ownership_controls" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  provider = aws.use1

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Set the ACL to private for the S3 bucket
resource "aws_s3_bucket_acl" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  provider = aws.use1
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.waf_logs]
}

# Create an IAM role to allow WAF to write logs to the S3 bucket
resource "aws_iam_role" "waf_logging_role2" {
  name = "${var.project}-waf-logging-role2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "wafv2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policy to the IAM role allowing it to write to the S3 bucket
resource "aws_iam_role_policy" "waf_logging_policy2" {
  name = "${var.project}-waf-logging-policy"
  role = aws_iam_role.waf_logging_role2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.waf_logs.bucket}/*"
      }
    ]
  })
}

# Configure the WAFv2 Web ACL logging configuration to send logs to the S3 bucket
resource "aws_wafv2_web_acl_logging_configuration" "cf_waf02_logging" {
  resource_arn = aws_wafv2_web_acl.cf_waf02.arn

  log_destination_configs = [
    "arn:aws:s3:::${aws_s3_bucket.waf_logs.bucket}"
  ]

  #role_arn = aws_iam_role.waf_logging_role.arn

  # Optional: redact sensitive fields from logs
  # redacted_fields {
  #   single_header {
  #     name = "authorization"
  #   }
  # }
}