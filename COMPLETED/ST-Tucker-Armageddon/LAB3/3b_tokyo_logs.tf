# tokyo_logs.tf
# resource "random_id" "id" {
#   byte_length = 8
# }
data "aws_caller_identity" "current" {}

# resource "aws_s3_bucket" "audit_log_vault" {
#   bucket = "arma-lab3-bucket"
#   # No provider needed if your default is Tokyo
# }

data "aws_s3_bucket" "audit_log_vault" {
  bucket = "arma-lab3-bucket"
}

# 1. Enable Versioning (Immutability)
resource "aws_s3_bucket_versioning" "audit_vault_versioning" {
  bucket = data.aws_s3_bucket.audit_log_vault.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 2. Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "vault_encryption" {
  bucket = data.aws_s3_bucket.audit_log_vault.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 3. Block Public Access (Auditors love this)
resource "aws_s3_bucket_public_access_block" "vault_restriction" {
  bucket = data.aws_s3_bucket.audit_log_vault.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = false #set to allow Cloudtrail to validate
}

#auditors need to know that the logs are being collected properly. s3 needs a bucket policy to allow CF to drop off those logs.
resource "aws_s3_bucket_policy" "allow_cloudfront_logging" {
  bucket = data.aws_s3_bucket.audit_log_vault.id

  # This ensures the bucket is ready for the policy
  depends_on = [aws_s3_bucket_acl.audit_vault_acl]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = "arn:aws:s3:::arma-lab3-bucket"
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        # Using the dynamic account ID for precision
        Resource = "arn:aws:s3:::arma-lab3-bucket/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid       = "CloudFrontLogging"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::arma-lab3-bucket/Chwebacca-logs/*"
        # Removed the SourceArn condition temporarily to simplify validation
      }
    ]
  })
}

# 1. Enable ACLs on the bucket
resource "aws_s3_bucket_ownership_controls" "audit_vault_controls" {
  bucket = data.aws_s3_bucket.audit_log_vault.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "audit_vault_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.audit_vault_controls]

  bucket = data.aws_s3_bucket.audit_log_vault.id
  acl    = "private" # CloudFront will manage its own log access
}