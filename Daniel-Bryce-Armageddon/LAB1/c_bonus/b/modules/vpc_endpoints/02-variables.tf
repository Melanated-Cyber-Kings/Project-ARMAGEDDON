variable "region" {
  type        = string
  description = "The AWS region to deploy resources in"
}

variable "vpc_id" {
  description = "ID of the VPC where endpoints will be created"
  type        = string
}

variable "vpc_endpoint_sg_id" {
  description = "Security group ID for VPC endpoint interfaces"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for interface endpoints"
  type        = list(string)
}

variable "route_table_ids" {
  description = "List of all route table IDs for S3 Gateway endpoint"
  type        = list(string)
  default     = []
  
  validation {
    condition     = length(var.route_table_ids) > 0
    error_message = "At least one route table ID is required for S3 endpoint."
  }
}

variable "prefix" {
  description = "Prefix for resource names and tags"
  type        = string
  default     = "lab"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "enable_kms_endpoint" {
  description = "Whether to create KMS VPC endpoint (optional)"
  type        = bool
  default     = false
}

variable "additional_endpoints" {
  description = "Map of additional VPC endpoints to create beyond defaults"
  type = map(object({
    service_name        = string
    vpc_endpoint_type   = string
    private_dns_enabled = optional(bool, true)
  }))
  default = {}
}

variable "endpoint_policy" {
  description = "Optional IAM policy to attach to endpoints"
  type        = string
  default     = null
}

variable "dns_hostnames_enabled" {
  description = "Whether to enable DNS hostnames in the VPC (required for private DNS)"
  type        = bool
  default     = true
}

variable "timeout_create" {
  description = "Timeout for endpoint creation"
  type        = string
  default     = "10m"
}

variable "timeout_update" {
  description = "Timeout for endpoint updates"
  type        = string
  default     = "10m"
}

variable "timeout_delete" {
  description = "Timeout for endpoint deletion"
  type        = string
  default     = "10m"
}

variable "security_group_rules" {
  description = "Additional security group rules for endpoint SG"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
    self        = optional(bool, false)
  }))
  default = []
}

# variable "create_security_group" {
#   description = "Whether to create a security group for endpoints"
#   type        = bool
#   default     = false
# }

variable "env_prefix" {
  description = "project environment"
  type = string
  default = "lab-1c"

  validation {
    condition = contains(["lab-1a", "lab-1b", "lab-1c"], var.env_prefix)
      error_message = "The environment must be one of: lab-1b, lab-1b or lab-1c"
  }
}


# variable "vpce_ssm_id" {
#   type = string
# }

# variable "vpce_logs_id" {
#   type = string
# }

# variable "vpce_secrets_id" {
#   type = string
# }

# variable "vpce_s3_id" {
#   type = string
# }