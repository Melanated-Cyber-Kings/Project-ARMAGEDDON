variable "env_prefix" {
  description = "Environment prefix for naming"
  type        = string
}

variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3"
  type        = bool
  default     = true
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs"
  type        = string
}

variable "bucket_name" {
  description = "Custom bucket name (optional)"
  type        = string
  default     = ""
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}