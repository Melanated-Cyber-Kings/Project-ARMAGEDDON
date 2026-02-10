###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: secrets
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

variable "region" {
  type        = string
  description = "The AWS region to deploy resources in"
}

variable "env_prefix" {
  description = "project environment"
  type        = string
  default     = "lab-1c"

  validation {
    condition     = contains(["lab-1a", "lab-1c", "lab-1c"], var.env_prefix)
    error_message = "The environment must be one of: lab-1a, lab-1c or lab-1c"
  }
}

variable "username" {
  description = "RDS master/app username"
  type        = string
}

variable "password" {
  description = "RDS master/app password"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Access port to the RDS DB"
  type        = number
}

variable "address" {
  description = "DB endpoint/hostname (not set in secrets; written later by envs)."
  type        = string
  default     = ""
}

variable "dbname" {
  description = "Initial database name"
  type        = string
}

###############################################################################
# Optional Secrets Rotation ( and beyond)
###############################################################################

variable "enable_rotation" {
  description = "Enable Secrets Manager rotation via Lambda (optional; default false)."
  type        = bool
  default     = false
}

variable "rotation_days" {
  description = "Days between automatic rotations"
  type        = number
  default     = 30
}

variable "rotation_lambda_arn" {
  description = "Rotation Lambda ARN (required only when enable_rotation = true)."
  type        = string
  default     = null
}

variable "manage_secret_value" {
  description = "Whether Terraform should write/update the secret value (SecretString). Set false to preserve existing value."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to the secret"
  type        = map(string)
  default     = {}
}
