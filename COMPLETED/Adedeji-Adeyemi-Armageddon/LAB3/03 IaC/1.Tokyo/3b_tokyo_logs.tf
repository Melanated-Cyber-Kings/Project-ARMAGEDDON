  data "aws_caller_identity" "current" {}


  ###########################
  ## Change Mod
  ###########################
  # resource "aws_s3_bucket" "audit_log_vault" {
  #   bucket = "class-lab3-200819971986"
  # }

  ###########################
  ## Change Mod
  ###########################
  /*

  # Change the name to something unique
  resource "aws_s3_bucket" "audit_log_vault" {
    bucket = "medical-vault-audit-logs-sprint3-${random_id.bucket_suffix.hex}" 
    # OR manually change it to something like:
    # bucket = "shinjuku-audit-vault-2026-v1"
  }

  # Add this to help with uniqueness
  resource "random_id" "bucket_suffix" {
    byte_length = 4
  }

  */

  resource "aws_s3_bucket" "audit_log_vault" {
    # Added 'sprint3' and 'v1' to ensure uniqueness
    bucket = "medical-vault-audit-logs-sprint3-v1-200819971986" 
    
    force_destroy = true # Good for lab environments
  }

  #################################
  ##change mod end
  #################################



  # 1. Enable Versioning
  resource "aws_s3_bucket_versioning" "audit_vault_versioning" {
    bucket = aws_s3_bucket.audit_log_vault.id
    versioning_configuration {
      status = "Enabled"
    }
  }

  # 2. Server-Side Encryption
  resource "aws_s3_bucket_server_side_encryption_configuration" "vault_encryption" {
    bucket = aws_s3_bucket.audit_log_vault.id
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  # 3. Block Public Access
  resource "aws_s3_bucket_public_access_block" "vault_restriction" {
    bucket = aws_s3_bucket.audit_log_vault.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = false #set to allow Cloudtrail to validate
  }

  # resource "aws_s3_bucket_policy" "allow_cloudfront_logging" {
  #   bucket = aws_s3_bucket.audit_log_vault.id

  #   depends_on = [aws_s3_bucket_acl.audit_vault_acl]

  #   policy = jsonencode({
  #     Version = "2012-10-17"
  #     Statement = [
  #       {
  #         Sid    = "AWSCloudTrailAclCheck"
  #         Effect = "Allow"
  #         Principal = { Service = "cloudtrail.amazonaws.com" }
  #         Action   = "s3:GetBucketAcl"
  #         Resource = "arn:aws:s3:::class-lab3-200819971986"
  #       },
  #       {
  #         Sid    = "AWSCloudTrailWrite"
  #         Effect = "Allow"
  #         Principal = { Service = "cloudtrail.amazonaws.com" }
  #         Action   = "s3:PutObject"
  #         # Using the dynamic account ID for precision
  #         Resource = "arn:aws:s3:::class-lab3-200819971986/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
  #         Condition = {
  #           StringEquals = {
  #             "s3:x-amz-acl" = "bucket-owner-full-control"
  #           }
  #         }
  #       },
  #       {
  #         Sid    = "CloudFrontLogging"
  #         Effect = "Allow"
  #         Principal = { Service = "cloudfront.amazonaws.com" }
  #         Action   = "s3:PutObject"
  #         Resource = "arn:aws:s3:::class-lab3-200819971986/Chwebacca-logs/*"
  #         # Removed the SourceArn condition temporarily to simplify validation
  #       }
  #     ]
  #   })
  # }

  # # 1. Enable ACLs on the bucket
  # resource "aws_s3_bucket_ownership_controls" "audit_vault_controls" {
  #   bucket = aws_s3_bucket.audit_log_vault.id
  #   rule {
  #     object_ownership = "BucketOwnerPreferred"
  #   }
  # }

  # resource "aws_s3_bucket_acl" "audit_vault_acl" {
  #   depends_on = [aws_s3_bucket_ownership_controls.audit_vault_controls]

  #   bucket = aws_s3_bucket.audit_log_vault.id
  #   acl    = "private" # CloudFront will manage its own log access
  # }



  #change mod
  #Begin
  # resource "aws_s3_bucket_policy" "allow_cloudfront_logging" {
  #   bucket = aws_s3_bucket.audit_log_vault.id

  #   # Ensures ACLs are ready before applying the policy
  #   depends_on = [aws_s3_bucket_acl.audit_vault_acl]

  #   policy = jsonencode({
  #     Version = "2012-10-17"
  #     Statement = [
  #       {
  #         Sid       = "AWSCloudTrailAclCheck"
  #         Effect    = "Allow"
  #         Principal = { Service = "cloudtrail.amazonaws.com" }
  #         Action    = "s3:GetBucketAcl"
  #         # FIX: Dynamic ARN
  #         Resource  = "${aws_s3_bucket.audit_log_vault.arn}"
  #       },
  #       {
  #         Sid       = "AWSCloudTrailWrite"
  #         Effect    = "Allow"
  #         Principal = { Service = "cloudtrail.amazonaws.com" }
  #         Action    = "s3:PutObject"
  #         # FIX: Dynamic ARN with path
  #         Resource  = "${aws_s3_bucket.audit_log_vault.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
  #         Condition = {
  #           StringEquals = {
  #             "s3:x-amz-acl" = "bucket-owner-full-control"
  #           }
  #         }
  #       },
  #       {
  #         Sid       = "CloudFrontLogging"
  #         Effect    = "Allow"
  #         Principal = { Service = "cloudfront.amazonaws.com" }
  #         Action    = "s3:PutObject"
  #         # FIX: Dynamic ARN with CloudFront prefix
  #         Resource  = "${aws_s3_bucket.audit_log_vault.arn}/Chwebacca-logs/*"
  #       }
  #     ]
  #   })
  # }

  # resource "aws_s3_bucket_ownership_controls" "audit_vault_oc" {
  #   bucket = aws_s3_bucket.audit_log_vault.id
  #   rule {
  #     object_ownership = "BucketOwnerPreferred"
  #   }
  # }

  # resource "aws_s3_bucket_acl" "audit_vault_acl" {
  #   depends_on = [aws_s3_bucket_ownership_controls.audit_vault_oc]
  #   bucket     = aws_s3_bucket.audit_log_vault.id
  #   acl        = "private"
  # }

  # 1. Ensure Ownership Controls allow ACLs
  resource "aws_s3_bucket_ownership_controls" "audit_vault_oc" {
    bucket = aws_s3_bucket.audit_log_vault.id
    rule {
      object_ownership = "BucketOwnerPreferred"
    }
  }

  # 2. Explicitly enable the ACL required by CloudFront
  resource "aws_s3_bucket_acl" "audit_vault_acl" {
    depends_on = [aws_s3_bucket_ownership_controls.audit_vault_oc]
    bucket     = aws_s3_bucket.audit_log_vault.id
    acl        = "private" 
  }

  # 3. Corrected Policy with Dynamic ARNs
  resource "aws_s3_bucket_policy" "allow_cloudfront_logging" {
    bucket = aws_s3_bucket.audit_log_vault.id

    # Critical: Wait for ACLs to be enabled first
    depends_on = [aws_s3_bucket_acl.audit_vault_acl]

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "AWSCloudTrailAclCheck"
          Effect    = "Allow"
          Principal = { Service = "cloudtrail.amazonaws.com" }
          Action    = "s3:GetBucketAcl"
          Resource  = "${aws_s3_bucket.audit_log_vault.arn}"
        },
        {
          Sid       = "AWSCloudTrailWrite"
          Effect    = "Allow"
          Principal = { Service = "cloudtrail.amazonaws.com" }
          Action    = "s3:PutObject"
          Resource  = "${aws_s3_bucket.audit_log_vault.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
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
          Resource  = "${aws_s3_bucket.audit_log_vault.arn}/Chwebacca-logs/*"
        }
      ]
    })
  }

  #END

