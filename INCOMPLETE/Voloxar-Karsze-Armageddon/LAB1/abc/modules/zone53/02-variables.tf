
variable "env_prefix" {
  type = string
}

variable "domain_name" {
  type    = string
  default = "example.com"
}

variable "project" {
  description = "project name"
  type = string
}

variable "subdomain" {
  description = "where is the app?"
  type = string
}

variable "zone_id" {
  type = string
}

variable "alb_dns_name" {
  type = string
}