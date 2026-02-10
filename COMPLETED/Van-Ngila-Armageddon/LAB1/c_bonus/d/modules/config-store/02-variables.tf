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
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}