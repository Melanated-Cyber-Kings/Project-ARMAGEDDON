# variable "domain_name" {
#   description = "Base domain students registered (e.g., chewbacca-growl.com)."
#   type        = string
#   default     = ""  #empty to skip custom dns
# }

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "theowafhomework.site"
}

variable "app_subdomain" {
  description = "Subdomain for the application"
  type        = string
  default     = "app"  # Will create app.theowafhomework.site
}

variable "env_prefix" {
  type        = string
  description = "Environment prefix for naming VPC and subnets"
}

variable "enable_waf" {
  description = "Toggle WAF creation."
  type        = bool
  default     = true
}

variable "alb_arn" {
  description = "ARN of the ALB for WAF association"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}

variable "alb_zone_id" {
  description = "Route53 zone ID of the ALB"
  type        = string
}

variable "create_validation_records" {
  description = "Whether to create ACM validation records"
  type        = bool
  default     = true
}

variable "wait_for_validation" {
  description = "Whether to wait for certificate validation"
  type        = bool
  default     = true
}