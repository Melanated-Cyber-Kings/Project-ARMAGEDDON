###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: general
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

variable "db_endpoint" {
  description = "RDS endpoint"
  type        = string
}

variable "db_port" {
  description = "RDS port"
  type        = string
}

variable "db_name" {
  description = "RDS database name"
  type        = string
}

variable "db_username" {
  description = "RDS username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags applied to Terraform backend resources."
  type        = map(string)
  default     = {}
}