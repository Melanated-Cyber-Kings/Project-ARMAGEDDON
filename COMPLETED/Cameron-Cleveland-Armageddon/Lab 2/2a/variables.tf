# variables.tf
variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "domain_name" {
  description = "Main domain name (e.g., givenchyops.com)"
  type        = string
}

variable "app_subdomain" {
  description = "Application subdomain (e.g., app)"
  type        = string
  default     = "app"
}

variable "cloudfront_acm_cert_arn" {
  description = "ACM certificate ARN in us-east-1 for CloudFront"
  type        = string
  default     = "" # Will be created by Terraform
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

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

variable "existing_vpc_id" {
  description = "Existing VPC ID"
  type        = string
  default     = "vpc-0892114ea951d975e"
}

variable "custom_header_name" {
  description = "Custom header name for origin cloaking"
  type        = string
  default     = "X-Chewbacca-Growl"
}

variable "custom_header_value" {
  description = "Custom header value for origin cloaking"
  type        = string
  default     = "wookiee-secret-key"
}
