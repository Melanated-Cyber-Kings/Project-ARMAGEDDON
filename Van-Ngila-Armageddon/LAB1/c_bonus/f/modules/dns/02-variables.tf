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

variable "create_apex_record" {
  description = "Create apex (root) domain record"
  type        = bool
  default     = false  # Enable for Bonus D
}

variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3"
  type        = bool
  default     = true
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs"
  type        = string
  default     = "alb-access-logs"
}
#############################################
#BONUS E
variable "waf_log_destination" {
  description = "Choose ONE destination per WebACL: cloudwatch | s3 | firehose"
  type        = string
  default     = "cloudwatch"
}

variable "waf_log_retention_days" {
  description = "Retention for WAF CloudWatch log group."
  type        = number
  default     = 14
}

variable "enable_waf_sampled_requests_only" {
  description = "If true, students can optionally filter/redact fields later. (Placeholder toggle.)"
  type        = bool
  default     = false
}
