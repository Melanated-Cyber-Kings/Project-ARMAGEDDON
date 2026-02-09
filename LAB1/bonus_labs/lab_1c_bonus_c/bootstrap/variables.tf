###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: bootstrap
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

# ============================================================
# Project: Armageddon — AWS Terraform Labs
# Lab:     1B
# Scope:   LAB1/b/bootstrap
# File:    variables.tf
# Purpose: Input variables for provisioning Terraform backend infrastructure.
# ============================================================

variable "region" {
  description = "AWS region where the Terraform backend resources will be created."
  type        = string
}

variable "tf_state_bucket_name" {
  description = "Globally-unique S3 bucket name for Terraform state storage."
  type        = string
}

variable "tf_lock_table_name" {
  description = "DynamoDB table name for Terraform state locking."
  type        = string
  default     = "terraform-state-locks"
}

variable "tags" {
  description = "Tags applied to Terraform backend resources."
  type        = map(string)
  default     = {}
}
