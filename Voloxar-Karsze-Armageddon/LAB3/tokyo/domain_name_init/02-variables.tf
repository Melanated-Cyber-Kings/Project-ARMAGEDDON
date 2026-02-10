
variable "env_prefix" {
  type = string
}

variable "domain_name" {
  type    = string
  default = "example.com"
}

variable "region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = ""
}