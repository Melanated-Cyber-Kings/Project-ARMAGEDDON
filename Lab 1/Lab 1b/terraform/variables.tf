variable "project_name" {
  type        = string
  default     = "chewbacca"
  description = "Project name for tagging"
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

variable "app_port" {
  description = "Port on which the application runs"
  type        = number
  default     = 80
}

variable "manage_route53_in_terraform" {
  description = "If true, create/manage Route53 hosted zone + records in Terraform."
  type        = bool
  default     = true
}

variable "route53_hosted_zone_id" {
  description = "If manage_route53_in_terraform=false, provide existing Hosted Zone ID for domain."
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Main domain name"
  type        = string
  default     = "givenchyops.com"
}

variable "app_subdomain" {
  description = "Application subdomain (e.g., app)"
  type        = string
  default     = "app"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "env_prefix" {
  description = "Environment prefix for naming"
  type        = string
  default     = "lab-1b"
}

variable "project" {
  description = "Project name (alternative to project_name)"
  type        = string
  default     = "Armageddon"
}
