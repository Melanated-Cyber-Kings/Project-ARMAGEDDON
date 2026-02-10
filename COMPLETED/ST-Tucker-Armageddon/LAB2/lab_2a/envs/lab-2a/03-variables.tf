###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: environment
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

###############################################################################
# Global
###############################################################################
variable "region" {
  type        = string
  description = "AWS region to deploy resources in (Lab-2 uses us-east-1)."
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "project" {
  description = "Project name (tagging / naming helper)"
  type        = string
  default     = "armageddon"
}

variable "env_prefix" {
  description = "Environment naming prefix"
  type        = string
  default     = "lab-2a"

  validation {
    condition     = lower(var.env_prefix) == "lab-2a"
    error_message = "env_prefix must be 'lab-2a'."
  }
}

variable "tags" {
  description = "Common tags applied to resources."
  type        = map(string)
  default     = {}
}

###############################################################################
# Network
###############################################################################
variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
}

variable "avail_zone_1" {
  description = "Availability zone 1"
  type        = string
}

variable "avail_zone_2" {
  description = "Availability zone 2"
  type        = string
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR (AZ1)"
  type        = string
}

variable "public_subnet_cidr_2" {
  description = "Public subnet CIDR (AZ2)"
  type        = string
}

variable "private_subnet_cidr_1" {
  description = "Private subnet CIDR (AZ1)"
  type        = string
}

variable "private_subnet_cidr_2" {
  description = "Private subnet CIDR (AZ2)"
  type        = string
}

variable "rtb_public_cidr" {
  description = "Public route table destination CIDR (usually 0.0.0.0/0)"
  type        = string
}

###############################################################################
# EC2
###############################################################################
variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

###############################################################################
# Database seed values (used by RDS module and secrets module)
###############################################################################
variable "db_name" {
  description = "Application database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database username."
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Database password (do not commit). Required when manage_secret_value=true."
  type        = string
  sensitive   = true
  default     = null

  validation {
    condition     = var.manage_secret_value == false || (var.db_password != null && length(var.db_password) >= 12)
    error_message = "When manage_secret_value=true, db_password must be set and should be at least 12 characters."
  }
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS."
  type        = bool
  default     = false
}

###############################################################################
# Secrets Manager behavior
###############################################################################
variable "manage_secret_value" {
  description = "If true, Terraform writes/updates SecretString for the DB secret."
  type        = bool
  default     = true
}

###############################################################################
# Secrets rotation
###############################################################################
variable "enable_rotation" {
  description = "Enable Secrets Manager rotation schedule."
  type        = bool
  default     = true
}

variable "rotation_days" {
  description = "Rotation interval (days) when enable_rotation=true."
  type        = number
  default     = 30
}

###############################################################################
# KMS / Alerting
###############################################################################
variable "kms_key_arn" {
  type        = string
  description = "KMS Key ARN used by IAM module (if applicable)."
}

variable "alert_email" {
  type        = string
  description = "Email to subscribe to SNS alerts"
}

###############################################################################
# App / ALB module inputs
###############################################################################
variable "app_port" {
  description = "Port the EC2 application listens on (target group port)."
  type        = number
  default     = 80
}

###############################################################################
# DNS / Route53 (Bonus-B baseline leveraged by LAB-2A)
###############################################################################

variable "domain_name" {
  description = "Base domain for the lab (hosted zone)."
  type        = string
}

variable "app_subdomain" {
  description = "Subdomain label for app record (e.g., app)."
  type        = string
  default     = "app"
}

variable "enable_route53" {
  description = "Whether to manage Route53 records as part of this environment."
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Hosted zone ID when enable_route53=true."
  type        = string
  default     = null
}

###############################################################################
# ALB 5XX alarm tuning (used by 06-ingress-alb.tf and bonus_b_observability.tf)
###############################################################################

variable "alb_5xx_threshold" {
  description = "Threshold for ALB 5XX alarm."
  type        = number
  default     = 10
}

variable "alb_5xx_period_seconds" {
  description = "Period (seconds) for ALB 5XX alarm."
  type        = number
  default     = 300
}

variable "alb_5xx_evaluation_periods" {
  description = "Evaluation periods for ALB 5XX alarm."
  type        = number
  default     = 1
}

###############################################################################
# LAB-2A: CloudFront Origin Cloaking (CloudFront -> ALB only)
###############################################################################


variable "origin_header_name" {
  description = "HTTP header CloudFront adds to origin requests; ALB requires it."
  type        = string
  default     = "X-Origin-Verify"
}

