###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: secrets
# PURPOSE: Define inputs for Secrets Manager module that creates/updates
#          the RDS credential secret and optionally configures rotation.
###############################################################################

###############################################################################
# Core Inputs
###############################################################################

variable "region" {
  type        = string
  description = "AWS region (optional; currently informational)."
}

variable "env_prefix" {
  description = "Project environment / naming prefix (lab-1a, lab-1b, lab-1c)."
  type        = string
  default     = "lab-1c"

  validation {
    condition     = contains(["lab-1a", "lab-1b", "lab-1c"], var.env_prefix)
    error_message = "env_prefix must be one of: lab-1a, lab-1b, lab-1c"
  }
}

variable "tags" {
  description = "Additional tags to apply to the secret."
  type        = map(string)
  default     = {}
}

###############################################################################
# RDS Credential Payload (required for secret creation/update)
###############################################################################

variable "username" {
  description = "RDS master/app username."
  type        = string
}

variable "password" {
  description = "RDS master/app password."
  type        = string
  sensitive   = true
}

variable "dbname" {
  description = "Initial database name."
  type        = string
}

variable "address" {
  description = "DB endpoint/hostname (written by env after RDS exists)."
  type        = string
  default     = ""
}

variable "port" {
  description = "Access port to the RDS DB."
  type        = number
  default     = 3306
}

###############################################################################
# Secret Value Management
###############################################################################

variable "manage_secret_value" {
  description = "Whether Terraform should always write/update the SecretString. Leave true for grading."
  type        = bool
  default     = true
}

###############################################################################
# Optional Secrets Rotation (Required when enable_rotation=true)
###############################################################################

variable "enable_rotation" {
  description = "Enable Secrets Manager rotation via Lambda."
  type        = bool
  default     = false
}

variable "rotation_days" {
  description = "Days between automatic rotations."
  type        = number
  default     = 30
}

variable "rotation_lambda_arn" {
  description = "Rotation Lambda ARN (required when enable_rotation=true)."
  type        = string
  default     = null
}
