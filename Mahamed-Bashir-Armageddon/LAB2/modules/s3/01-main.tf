terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = merge({ Name = var.bucket_name }, var.tags)
}


resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = false # Set to false to allow the logging ACL
  block_public_policy     = true
  ignore_public_acls      = false # Set to false to allow the logging ACL
  restrict_public_buckets = true
}


resource "aws_s3_bucket_acl" "log_delivery" {
  bucket = aws_s3_bucket.this.id
  acl    = "log-delivery-write"

  depends_on = [
    aws_s3_bucket_ownership_controls.this,
    aws_s3_bucket_public_access_block.this,
  ]
}