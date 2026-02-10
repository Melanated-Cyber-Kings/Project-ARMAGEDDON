###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: security
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

###############################################################################
# modules/security/05-variables.tf
###############################################################################

variable "env_prefix" {
  type        = string
  description = "Environment prefix used for naming."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "tags" {
  type        = map(string)
  description = "Common resource tags."
  default     = {}
}

###############################################################################
# EC2 / RDS ingress
###############################################################################

variable "alb_to_ec2_port" {
  description = "Port ALB uses to reach EC2."
  type        = number
  default     = 80
}

variable "tcp_ingress_rule" {
  description = "TCP ingress rule for RDS from EC2."
  type = object({
    port        = number
    description = string
  })
}

###############################################################################
# ALB ingress controls (LAB-2B STEP-2)
###############################################################################

variable "alb_ingress_mode" {
  description = <<EOF
How ALB inbound traffic is allowed:

cloudfront_prefix_list = only CloudFront may reach ALB
public_443             = internet can reach ALB, header rule blocks
EOF
  type    = string
  default = "cloudfront_prefix_list"

  validation {
    condition     = contains(["cloudfront_prefix_list", "public_443"], var.alb_ingress_mode)
    error_message = "alb_ingress_mode must be cloudfront_prefix_list or public_443."
  }
}

variable "alb_allow_http_80" {
  description = "Allow public HTTP 80 to ALB (redirect use-case)."
  type        = bool
  default     = false
}
