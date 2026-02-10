###############################################################################
# Ingress module inputs (Lab-1C Bonus D)
###############################################################################

variable "env_prefix" {
  type        = string
  description = "Environment/name prefix for resources."
}

variable "region" {
  type        = string
  description = "AWS region."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the ALB."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the ALB."
}

variable "alb_sg_id" {
  type        = string
  description = "Security group ID for the ALB."
}

#################################################################################
# ALB access logs to S3 bucket and correct permissions are required for ALB logging. 
# If enabled, ensure the S3 bucket exists and has a policy allowing the ALB to write logs. 
# The bucket should also have lifecycle policies to manage log retention.
# ALB access logs can be analyzed for traffic patterns, troubleshooting, and security monitoring.
# Related policy and bucket configuration are in alb_access_logs.tf.
##################################################################################

variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3."
  type        = bool
  default     = true
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs."
  type        = string
  default     = "alb-access-logs"
}
#################################################################################


variable "target_instance_id" {
  type        = string
  description = "EC2 instance ID to register into the target group."
}

variable "domain_name" {
  type        = string
  description = "Base domain for DNS + ACM (example: devlab405.click)."
}

variable "app_subdomain" {
  type        = string
  description = "Subdomain for the application (example: app)."
  default     = "app"
}

variable "app_port" {
  type        = number
  description = "Port the application listens on (target group port)."
  default     = 80
}

###############################################################################
# DNS Mode (Option 2)
# - route53_managed  : Terraform creates hosted zone + records
# - route53_existing : Use existing hosted zone id + records
# - external         : DNS not managed in Terraform; output validation records
###############################################################################

variable "dns_mode" {
  type        = string
  description = "DNS mode: route53_managed | route53_existing | external"
  default     = "route53_existing"

  validation {
    condition     = contains(["route53_managed", "route53_existing", "external"], var.dns_mode)
    error_message = "dns_mode must be one of: route53_managed, route53_existing, external."
  }
}

variable "route53_hosted_zone_id" {
  type        = string
  description = "Existing Route53 hosted zone ID when dns_mode=route53_existing."
  default     = ""
}

# External-mode safety:
# ACM cert is requested, but DNS validation must be completed outside Terraform.
# HTTPS listener requires an ISSUED cert. Set this true only AFTER cert is ISSUED.
variable "enable_https_in_external" {
  type        = bool
  description = "If dns_mode=external, set true only after cert is ISSUED to allow HTTPS listener creation."
  default     = false
}

###############################################################################
# SNS / Observability (SNS is mandatory)
###############################################################################

variable "alarm_action_topic_arn" {
  type        = string
  description = "SNS topic ARN for alarms (required)."
}

variable "alb_5xx_evaluation_periods" {
  type        = number
  description = "Number of periods to evaluate for ALB 5xx alarm."
  default     = 1
}

variable "alb_5xx_period_seconds" {
  type        = number
  description = "Period (seconds) for ALB 5xx metric."
  default     = 300
}

variable "alb_5xx_threshold" {
  type        = number
  description = "Threshold for ALB 5xx alarm."
  default     = 5
}

###############################################################################
# WAF Logging
###############################################################################

variable "waf_log_destination" {
  type        = string
  description = "Choose ONE destination per WebACL: cloudwatch | s3 | firehose"
  default     = "cloudwatch"

  validation {
    condition     = contains(["cloudwatch", "s3", "firehose"], var.waf_log_destination)
    error_message = "waf_log_destination must be one of: cloudwatch, s3, firehose."
  }
}

variable "waf_log_retention_days" {
  type        = number
  description = "Retention for WAF CloudWatch log group (days)."
  default     = 14
}

variable "enable_waf_sampled_requests_only" {
  type        = bool
  description = "If true, sampled requests only / redaction (implementation dependent)."
  default     = false
}
