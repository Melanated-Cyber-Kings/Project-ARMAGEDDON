variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "db_endpoint" {
  type = string
}

variable "db_port" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "account_id" {
  type = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"  # Change from us-east-1 to ap-northeast-1
}

# Add this variable:
variable "existing_alb_name" {
  description = "Name of existing ALB from Lab 1"
  type        = string
  default     = "chewbacca-alb01"
}

variable "existing_zone_id" {
  description = "Existing Route53 zone ID"
  type        = string
  default     = "Z064076128W8FV0DP91X1"
}
