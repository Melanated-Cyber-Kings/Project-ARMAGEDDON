

# variable "certificate_validation_method" {
#   description = "ACM validation method. Students can do DNS (Route53) or EMAIL."
#   type        = string
#   default     = "DNS"
# }

variable "domain_name" {
  description = "The root domain name (e.g., lewsdomain.com)"
  type        = string
  default     = "projectcomplete.me"
}

variable "app_subdomain" {
  description = "The subdomain for the app (e.g., app)"
  type        = string
  default     = "app"
}

variable "route53_hosted_zone_id" {
  description = "Existing Hosted Zone ID if manage_route53_in_terraform is false."
  type        = string
  default     = ""
}

variable "manage_route53_in_terraform" {
  description = "Set to true to create the Hosted Zone in this stack."
  type        = bool
  default     = true
}


############################################
# Lab 1d_bonus-E
############################################
variable "enable_waf" {
  description = "Toggle to attach WAF to the ALB."
  type        = bool
  default     = true
}

variable "waf_log_retention_days" {
  description = "How long to keep WAF traffic logs."
  type        = number
  default     = 7
}