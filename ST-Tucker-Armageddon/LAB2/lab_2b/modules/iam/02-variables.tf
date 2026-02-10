###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: iam
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

variable "region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "env_prefix" {
  type        = string
  description = "Environment prefix for naming VPC and subnets"
}

variable "kms_key_arn" {
  description = "KMS CMK ARN used to encrypt the Secrets Manager secret"
  type        = string
}

variable "tags" {
  description = "Tags applied to Terraform backend resources."
  type        = map(string)
  default     = {}
}