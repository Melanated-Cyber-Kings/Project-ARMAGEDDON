# provider "aws" {
#   region = "us-east-1" #cloudwatch global location
#   alias = "use1"
# }

# resource "aws_s3_bucket" "waf_logs" {
#   bucket = lower("aws-waf-logs-${var.project}-tokyo-${random_string.short_string.result}")
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

# resource "aws_wafv2_web_acl_logging_configuration" "cf_waf01_logging" {
#   resource_arn = aws_wafv2_web_acl.cf_waf01.arn
  


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

# data "aws_caller_identity" "current" {}


# resource "aws_s3_bucket_policy" "waf_logs" {
#   #provider = aws.use1  # Match bucket region
#   bucket   = aws_s3_bucket.waf_logs.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "WAFLogDelivery"
#         Effect = "Allow"
#         Principal = { Service = "delivery.logs.amazonaws.com" }
#         Action   = "s3:PutObject"
#         Resource = "${aws_s3_bucket.waf_logs.arn}/*"
#         Condition = {
#           StringEquals = {
#             "aws:SourceAccount" = data.aws_caller_identity.current.account_id
#             "aws:SourceArn" = aws_wafv2_web_acl.cf_waf01.arn
#           }
#         }
#       }
#     ]
#   })
#   depends_on = [aws_s3_bucket_acl.waf_logs]
# }


provider "aws" {
  region = "us-east-1" # CloudWatch global location
  alias  = "use1"
}

# Create an S3 bucket to store the WAF logs
resource "aws_s3_bucket" "waf_logs" {
  bucket = lower("aws-waf-logs-${var.project}-tokyo-${random_string.short_string.result}")
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
resource "aws_iam_role" "waf_logging_role" {
  name = "${var.project}-waf-logging-role"

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
resource "aws_iam_role_policy" "waf_logging_policy" {
  name = "${var.project}-waf-logging-policy"
  role = aws_iam_role.waf_logging_role.id

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
resource "aws_wafv2_web_acl_logging_configuration" "cf_waf01_logging" {
  resource_arn = aws_wafv2_web_acl.cf_waf01.arn

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