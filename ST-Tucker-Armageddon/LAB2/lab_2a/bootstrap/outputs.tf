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
# File:    outputs.tf
# Purpose: Output backend values for use in secrets/env initialization.
# ============================================================

output "region" {
  description = "AWS region used for backend resources."
  value       = var.region
}

output "tf_state_bucket_name" {
  description = "S3 bucket name for Terraform state."
  value       = aws_s3_bucket.tf_state.bucket
}

output "tf_lock_table_name" {
  description = "DynamoDB table name for Terraform state locking."
  value       = aws_dynamodb_table.tf_locks.name
}
