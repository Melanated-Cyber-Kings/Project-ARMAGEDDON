# Add to your existing variables.tf
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

# Add to your existing variables.tf
variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "chewbacca"
}

variable "domain_name" {
  description = "Main domain name (e.g., chewbacca-growl.com)"
  type        = string
  default     = "chewbacca-growl.com"
}

variable "app_subdomain" {
  description = "Application subdomain (e.g., app)"
  type        = string
  default     = "app"
}

