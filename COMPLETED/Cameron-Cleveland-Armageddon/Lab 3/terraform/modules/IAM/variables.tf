variable "name_prefix" {
  description = "Prefix for IAM resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "enable_s3_access" {
  description = "Whether to attach S3 read-only policy"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "S3 bucket name for read access (if enabled)"
  type        = string
  default     = ""
}

variable "iam_instance_profile" {
  description = "IAM instance profile name for SSM access"
  type        = string
  default     = ""  # Make optional
}