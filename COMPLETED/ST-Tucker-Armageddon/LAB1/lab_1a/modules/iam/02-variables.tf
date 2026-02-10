###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: iam
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

variable "region" {
  type        = string
  description = "AWS region."
}

variable "account_id" {
  type        = string
  description = "AWS account ID."
}

variable "env_prefix" {
  type        = string
  description = "Prefix for IAM resource names."
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN used to decrypt Secrets Manager secret."
}

# NEW — used to scope Secrets Manager permissions tightly
variable "secret_arn" {
  type        = string
  description = "ARN of the Secrets Manager secret EC2 is allowed to read."
}
