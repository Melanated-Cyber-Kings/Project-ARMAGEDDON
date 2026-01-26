variable "region" {
  type        = string
  description = "The AWS region to deploy resources in"
}

variable "env_prefix" {
  description = "project environment"
  type = string
  default = "lab-1a"

  validation {
    condition = contains(["lab-1a", "lab-1b", "lab-1c"], var.env_prefix)
      error_message = "The environment must be one of: lab-1a, lab-1b or lab-1c"
  }
}


variable "username" {
  description = "RDS master username"
  type        = string
  sensitive   = true
}

variable "password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

#variable "address" {
#description = "RDS endpoint or hostname"
#  type        = string
#}

variable "port" {
  description = "Database port"
  type        = number
  default     = 3306
}

variable "dbname" {
  description = "Database name"
  type        = string
}