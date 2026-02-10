###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: secrets
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

# ============================================================
# LAB1A — Secrets Bootstrap Variables
# ============================================================

# -----------------
# AWS / Region
# -----------------

variable "region" {
  type        = string
  description = "AWS region to deploy Secrets Manager resources into."
}

variable "account_id" {
  type        = string
  description = "12-digit AWS account ID."
}

# -----------------
# KMS
# -----------------

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key used to encrypt the secret."
}

# -----------------
# Secret Metadata
# -----------------

variable "secret_name" {
  type        = string
  description = "Name of the Secrets Manager secret."
  default     = "lab-1a/rds/mysql"
}

variable "description" {
  type        = string
  description = "Description for the secret."
  default     = "LAB1A RDS credentials for EC2 → RDS connectivity"
}

# -----------------
# Secret Payload
# -----------------

variable "rds_username" {
  type        = string
  description = "Database username stored in the secret."
}

variable "rds_password" {
  type        = string
  description = "Database password stored in the secret."
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "Database name stored in the secret."
  default     = "labdb"
}

variable "port" {
  type        = number
  description = "Database port stored in the secret."
  default     = 3306
}

variable "address" {
  type        = string
  description = "RDS endpoint hostname. Placeholder at bootstrap, updated after RDS is created."
  default     = "PENDING_RDS_ENDPOINT"
}

# -----------------
# Rotation Lambda (Optional)
# -----------------

variable "rotation_lambda_arn" {
  type        = string
  description = "ARN of the Lambda function used for Secrets Manager rotation. Leave null to disable."
  default     = null
}
