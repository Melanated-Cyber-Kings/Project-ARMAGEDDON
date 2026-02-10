###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: bootstrap
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

# ============================================================
# Project: Armageddon — AWS Terraform Labs
# Lab:     1B
# Scope:   LAB1/b/bootstrap
# File:    backend-bootstrap.tf
# Purpose: Provision S3 (state) + DynamoDB (locking) for Terraform remote state.
#          Bucket is intended to persist; DynamoDB locks may be destroyed/recreated.
# ============================================================

provider "aws" {
  region = var.region
}

##############################################
# S3 Bucket for Terraform State (persistent)
##############################################

resource "aws_s3_bucket" "tf_state" {
  bucket = var.tf_state_bucket_name
  tags   = var.tags

  # Lab policy: keep the bucket (reuse across runs)
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

##############################################
# DynamoDB table for Terraform state locking
# (disposable for labs)
##############################################

resource "aws_dynamodb_table" "tf_locks" {
  name         = var.tf_lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = var.tags
}
