variable "region" {
  type        = string
  description = "The AWS region to deploy resources in"
}

variable "env_prefix" {
  description = "project environment"
  type = string
  default = "lab-1b"

  validation {
    condition = contains(["lab-1a", "lab-1b", "lab-1c"], var.env_prefix)
      error_message = "The environment must be one of: lab-1a, lab-1b or lab-1c"
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
  type = number
}

variable "address" {
  description = "The hostname of the RDS instance"
  type = string
}

variable "dbname" {
  description = "Initial database name"
  type        = string
}