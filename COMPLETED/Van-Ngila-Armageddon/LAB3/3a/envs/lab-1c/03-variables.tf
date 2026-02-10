variable "region" {
  type        = string
  description = "The AWS region to deploy resources in"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}


variable "vpc_cidr_block" {
  description = "VPC cidr block"
  type = string
}

#variable "env_prefix" {
#  type        = string
#  description = "Environment prefix for naming VPC and subnets"
#}

variable "env_prefix" {
  description = "project environment"
  type = string
  default = "lab-1c"

  validation {
    condition = contains(["lab-1a", "lab-1b", "lab-1c"], var.env_prefix)
      error_message = "The environment must be one of: lab-1a, lab-1b or lab-1c"
  }
}


variable "project" {
  description = "project name"
  type = string
}

variable "avail_zone_1" {
    description = "provider region, availability zone for resources"
    type = string
}

variable "avail_zone_2" {
    description = "provider region, availability zone for resources"
    type = string
}

variable "avail_zone_3" {
    description = "provider region, availability zone for resources"
    type = string
}

variable "rtb_public_cidr" {
  description = "route table public cidr"
  type = string
}

variable "public_subnet_cidr_1" {
  description = "public subnet cidr range"
  type = string
}

variable "public_subnet_cidr_2" {
  description = "public subnet cidr range"
  type = string
}

variable "private_subnet_cidr_1" {
  description = "private subnet cidr range"
  type = string
}

variable "private_subnet_cidr_2" {
  description = "private subnet cidr range"
  type = string
}

variable "private_subnet_cidr_3" {
  description = "public subnet cidr range"
  type = string
}

variable "instance_type" {
  type        = string
  description = "The type of EC2 instance to launch"
} 

variable "db_name" {
  description = "Initial database name."
  type        = string
}

variable "db_username" {
  description = "DB master username (students should use Secrets Manager in 1B/1C)."
  type        = string
}

variable "db_password" {
  description = "DB master password (DO NOT hardcode in real life; for lab only)."
  type        = string
  sensitive   = true
}


variable "kms_key_arn" {
  type = string
}

variable "alert_email" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_kms_endpoint" {
  description = "Enable KMS VPC endpoint"
  type        = bool
  default     = false
}

variable "alb_5xx_threshold" {
  description = "Alarm threshold for ALB 5xx count."
  type        = number
  default     = 10
}

variable "alb_5xx_period_seconds" {
  description = "CloudWatch alarm period."
  type        = number
  default     = 300
}

variable "alb_5xx_evaluation_periods" {
  description = "Evaluation periods for alarm."
  type        = number
  default     = 1
}

variable "enable_waf" {
  description = "Toggle WAF creation."
  type        = bool
  default     = true
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

# variable "acm_certificate_arn" {
#   type = string
# }

variable "create_apex_record" {
  description = "Create apex (root) domain record"
  type        = bool
  default     = true
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

variable "alb_access_logs_bucket_name" {
  description = "Name of S3 bucket for ALB access logs"
  type        = string
  default     = ""
}

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

variable "saopaulo_vpc_cidr" {
  description = "CIDR block for São Paulo VPC (must not overlap with Tokyo VPC)"
  type        = string
  default     = "172.18.0.0/16"  # Default that won't overlap with Tokyo 172.17.0.0/16
}