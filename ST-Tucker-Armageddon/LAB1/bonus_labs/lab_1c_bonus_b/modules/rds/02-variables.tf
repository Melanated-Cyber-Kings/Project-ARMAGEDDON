###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: rds
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

variable "db_name" {
  description = "Initial database name"
  type        = string
}
variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_subnet_group_name" {
  type = string
}

variable "rds_security_group_id" {
  type = string
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

# Added variable for Multi-AZ configuration. Default is true. 
# Set to false for testing or cost-saving purposes.
variable "multi_az" {
  description = "Whether the RDS instance should be deployed in Multi-AZ mode."
  type        = bool
  default     = true
}


variable "tags" {
  description = "Common tags applied to all resources in this lab."
  type        = map(string)
  default     = {}
}

