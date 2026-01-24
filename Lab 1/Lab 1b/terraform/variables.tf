variable "project_name" {
  type    = string
  default = "lab1b"
}

variable "environment" {
  type    = string
  default = "demo"
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "lab1b_app"
}