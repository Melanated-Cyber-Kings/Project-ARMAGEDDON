###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: secrets
# PURPOSE: Create/update the RDS credential secret and optionally configure rotation.
###############################################################################

###############################################################################
# Core Inputs
###############################################################################
variable "region" {
  type        = string
  description = "AWS region (informational; resources are created in the calling provider's region)."
}

variable "env_prefix" {
  description = "Environment naming prefix (example: lab-2a)."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to the secret."
  type        = map(string)
  default     = {}
}

###############################################################################
# Secret payload
###############################################################################
variable "username" {
  description = "DB username."
  type        = string
}

variable "password" {
  description = "DB password."
  type        = string
  sensitive   = true
}

variable "dbname" {
  description = "Database name."
  type        = string
}

variable "address" {
  description = "DB endpoint/hostname (typically module.rds.address)."
  type        = string
  default     = ""
}

variable "port" {
  description = "DB port."
  type        = number
  default     = 3306
}

###############################################################################
# Secret value management
###############################################################################
variable "manage_secret_value" {
  description = "If true, Terraform writes/updates SecretString."
  type        = bool
  default     = true
}

###############################################################################
# Rotation
###############################################################################
variable "enable_rotation" {
  description = "If true, attach Secrets Manager rotation schedule."
  type        = bool
  default     = true
}

variable "rotation_days" {
  description = "Days between rotations (when enable_rotation=true)."
  type        = number
  default     = 30
}

variable "rotation_lambda_arn" {
  description = "ARN of the rotation Lambda (required when enable_rotation=true)."
  type        = string
  default     = null
}
