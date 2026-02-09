###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: environment
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

###############################################################################
# Core Environment Inputs
###############################################################################

variable "region" {
  type        = string
  description = "The AWS region to deploy resources in"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "env_prefix" {
  description = "Project environment / naming prefix"
  type        = string
  default     = "lab-1c"

  # NOTE: your original validation listed lab-1c repeatedly; keep simple/accurate.
  validation {
    condition     = contains(["lab-1a", "lab-1b", "lab-1c"], var.env_prefix)
    error_message = "env_prefix must be one of: lab-1a, lab-1b, lab-1c"
  }
}

variable "tags" {
  description = "Tags applied to resources"
  type        = map(string)
  default     = {}
}

###############################################################################
# Network Inputs
###############################################################################

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
}

variable "avail_zone_1" {
  description = "Availability zone for resources"
  type        = string
}

variable "avail_zone_2" {
  description = "Second availability zone for resources"
  type        = string
}

variable "public_subnet_cidr" {
  description = "First public subnet CIDR range"
  type        = string
}

variable "public_subnet_cidr_2" {
  description = "Second public subnet CIDR range"
  type        = string
}

variable "private_subnet_cidr_1" {
  description = "First private subnet CIDR range"
  type        = string
}

variable "private_subnet_cidr_2" {
  description = "Second private subnet CIDR range"
  type        = string
}

variable "rtb_public_cidr" {
  description = "Route table public CIDR (usually 0.0.0.0/0)"
  type        = string
}

###############################################################################
# EC2 Inputs
###############################################################################

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

###############################################################################
# RDS Inputs / Secrets Seed (used by secrets module)
###############################################################################

variable "manage_secret_value" {
  description = "If true, env seeds Secrets Manager with db_username/db_password/db_name."
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Database name stored in Secrets Manager (and used by the app)."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "DB username stored in Secrets Manager."
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "DB password stored in Secrets Manager. Use a strong value in lab-1c.auto.tfvars (never commit secrets)."
  type        = string
  sensitive   = true
  default     = null

  validation {
    condition     = var.manage_secret_value == false || (var.db_password != null && length(var.db_password) >= 12)
    error_message = "When manage_secret_value=true, db_password must be set and should be at least 12 characters."
  }
}

variable "db_port" {
  description = "Database listener port (e.g., 3306 for MySQL, 5432 for PostgreSQL)"
  type        = number
  # Set a default port, but allow override for different database engines or custom configurations.
  default = 3306
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS."
  type        = bool
  default     = false
}

################################################################################
# Secrets Rotation (Set to OFF for Lab 1C to avoid complexity/cost, 
# but can be enabled for testing)
#  - If enabled, the rotation Lambda will attempt to rotate credentials every 30 days.
#  - Ensure db_username/db_password are valid and rotation-compatible if enabling.
################################################################################

variable "enable_rotation" {
  description = "Enable Secrets Manager rotation schedule. Keep false for grading runs to avoid teardown issues."
  type        = bool
  default     = false
}

variable "rotation_days" {
  description = "Rotation interval in days (only used when enable_rotation=true)."
  type        = number
  default     = 30
}


###############################################################################
# KMS / Alerting
###############################################################################

variable "kms_key_arn" {
  type        = string
  description = "KMS Key ARN (if used by modules)"
}

variable "alert_email" {
  type        = string
  description = "Email to subscribe to SNS alerts"
}

###############################################################################
#  — Ingress DNS / TLS / WAF / Observability
###############################################################################

variable "domain_name" {
  description = "Base domain owned by the user (example: example.com)"
  type        = string
}

variable "app_subdomain" {
  description = "Subdomain for the application"
  type        = string
  default     = "app"
}

variable "app_port" {
  description = "Port the EC2 application listens on (target group port)"
  type        = number
  default     = 80
}

###############################################################################
# DNS Mode (Option 2)
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
  description = "Existing Route53 Hosted Zone ID when dns_mode=route53_existing."
  default     = ""
}

###############################################################################
# ALB 5xx Alarm Tuning
###############################################################################

variable "alb_5xx_threshold" {
  description = "ALB 5xx threshold before alarm fires"
  type        = number
  default     = 10
}

variable "alb_5xx_period_seconds" {
  description = "Metric evaluation window (seconds)"
  type        = number
  default     = 300
}

variable "alb_5xx_evaluation_periods" {
  description = "Number of periods evaluated"
  type        = number
  default     = 1
}

###############################################################################
# WAF Logging
###############################################################################

variable "waf_log_destination" {
  description = "Choose ONE destination per WebACL: cloudwatch | s3 | firehose"
  type        = string
  default     = "cloudwatch"
}

variable "waf_log_retention_days" {
  description = "Retention for WAF CloudWatch logs (days)"
  type        = number
  default     = 14
}

variable "enable_waf_sampled_requests_only" {
  description = "Limit/redact sensitive fields in WAF logs"
  type        = bool
  default     = false
}
