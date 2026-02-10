# Commenting out the S3 bucket creation for lab 1c as I will used a Golden AMI with pre-baked dependencies.
resource "aws_s3_bucket" "alb_logs_bucket01" {
  bucket = "${local.name_prefix}-app-assets-${data.aws_caller_identity.current.account_id}"
  force_destroy  = true
}

# Ensure the bucket is private
resource "aws_s3_bucket_public_access_block" "alb_logs_public_access_block" {
  bucket = aws_s3_bucket.alb_logs_bucket01.id
  

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "alb_log_policy" {
  # Link to your existing bucket resource
  bucket = aws_s3_bucket.alb_logs_bucket01.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowALBLogs"
        Effect = "Allow"
        Principal = {
          # This ID (127311923021) is required for us-east-1 ALB logs
          AWS = "arn:aws:iam::127311923021:root"
        }
        Action   = "s3:PutObject"
        # The '/*' allows the ALB to write any log file into the bucket
        Resource = "${aws_s3_bucket.alb_logs_bucket01.arn}/*"
      }
    ]
  })
}
