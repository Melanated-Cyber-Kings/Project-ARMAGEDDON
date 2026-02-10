variable "project" {
  type = string
}

variable "domain_name" {
  type    = string
  default = "example.com"
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

variable "waf_arn" {
    type = string
}

variable targetgroup_arn {
    type = string
}

