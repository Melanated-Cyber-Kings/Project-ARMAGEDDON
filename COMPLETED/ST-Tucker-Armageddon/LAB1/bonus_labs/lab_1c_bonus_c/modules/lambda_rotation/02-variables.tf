###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: general
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

variable "engine" {
  description = "Database engine for rotation template: mysql or postgres."
  type        = string
  validation {
    condition     = contains(["mysql", "postgres"], var.engine)
    error_message = "engine must be one of: mysql, postgres"
  }
}

variable "stack_name" {
  description = "CloudFormation stack name for the SAR deployment."
  type        = string
}

variable "function_name" {
  description = "Name of the rotation Lambda function to deploy."
  type        = string
}

variable "enable_vpc" {
  description = "Whether to deploy the rotation Lambda into a VPC."
  type        = bool
  default     = true
}

variable "subnet_ids" {
  description = "Private subnet IDs for the rotation Lambda (if enable_vpc=true)."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs for the rotation Lambda (if enable_vpc=true)."
  type        = list(string)
  default     = []
}

variable "endpoint" {
  description = "Database endpoint/host required by the SAR rotation application (parameter: endpoint)."
  type        = string

  validation {
    condition     = length(var.endpoint) > 0
    error_message = "endpoint must be a non-empty string."
  }


}



variable "tags" {
  description = "Tags applied to the SAR CloudFormation stack."
  type        = map(string)
  default     = {}
}
