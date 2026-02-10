variable "account_id" {
  description = "AWS account ID"
  type        = string
}

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

#You’ll need this variable:
variable "cloudfront_acm_cert_arn" {
  description = "ACM certificate ARN in us-east-1 for CloudFront (covers theowafhomework.site and app.theowafhomework.site)."
  type        = string
}

# variable "shinjuku_cf_waf01_arn" {
#     description = "ARN waf for cloudfront"
#     type = string
# }

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

variable "cache_policy_static_id" {
  description = "Cache policy ID for static content (/static/*)"
  type        = string
  default     = null
}

variable "cache_policy_api_id" {
  description = "Cache policy ID for API endpoints (default behavior)"
  type        = string
  default     = null
}

variable "origin_request_policy_static_id" {
  description = "Origin request policy ID for static content"
  type        = string
  default     = null
}

variable "origin_request_policy_api_id" {
  description = "Origin request policy ID for API endpoints"
  type        = string
  default     = null
}

variable "response_headers_policy_static_id" {
  description = "Response headers policy ID for static content"
  type        = string
  default     = null
}

variable "ordered_cache_behaviors" {
  description = "List of ordered cache behaviors for path patterns"
  type = list(object({
    path_pattern           = string
    cache_policy_id        = string
    origin_request_policy_id = string
    response_headers_policy_id = optional(string)
  }))
  default = []
}