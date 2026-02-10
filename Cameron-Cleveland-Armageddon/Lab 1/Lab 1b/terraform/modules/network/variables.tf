variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

# Change from list to single string
variable "availability_zone" {
  type = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}
variable "alb_security_group_id" {
  description = "ALB Security Group ID"
  type        = string
  default     = ""
}