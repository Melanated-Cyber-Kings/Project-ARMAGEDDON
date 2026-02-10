variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

# Change from subnet_id to subnet_ids (plural)
variable "subnet_ids" {
  type = list(string)
}

variable "database_security_group_id" {
  type = string
}

variable "region" {
  type = string
}

variable "account_id" {
  type = string
}