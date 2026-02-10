###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: security
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

variable "vpc_id" {
  description = "VPC ID where the RDS security group is created"
  type        = string
}

variable "env_prefix" {
  type = string
}

/*
variable "tcp_ingress_rule" {
  type = object({
    port        = number
    description = string
  })
}
*/

variable "tcp_ingress_rule" {
  description = "RDS MySQL access from EC2 security group"
  type = object({
    port        = number
    description = string
  })

  default = {
    port        = 3306
    description = "MySQL access from EC2"
  }
}


variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

# ALB to EC2 ingress rule variables
# Enable ALB -> EC2 ingress rule

variable "enable_alb_to_ec2" {
  description = "Enable ALB -> EC2 ingress rule"
  type        = bool
  default     = false
}

# Port on EC2 that ALB forwards to (e.g., 80 or 8080)
# Default is 80 if not specified when enable_alb_to_ec2 is true
# Used in security group rule for EC2 to allow traffic from ALB 
# security group on this port only to limit exposure of EC2 instances.

variable "alb_to_ec2_port" {
  description = "Port on EC2 that ALB forwards to (e.g., 80 or 8080)"
  type        = number
  default     = 80
}

# Tags variable
variable "tags" {
  description = "Common tags applied to all resources in this lab."
  type        = map(string)
  default     = {}
}

######################################################################################
# Control ALB to EC2 ingress rule creation with a boolean variable
# If enable_alb_to_ec2 is true, create a security group rule allowing traffic from 
#ALB to EC2 on the specified port.
# If false, do not create the rule, effectively blocking ALB access to EC2 instances.

variable "alb_ingress_mode" {
  description = "Controls ALB 443 ingress. 'public_443' = 0.0.0.0/0. 'cloudfront_prefix_list' = CloudFront prefix list only."
  type        = string
  #default     = "public_443"
  default = "cloudfront_prefix_list"

  validation {
    condition     = contains(["public_443", "cloudfront_prefix_list"], var.alb_ingress_mode)
    error_message = "alb_ingress_mode must be 'public_443' or 'cloudfront_prefix_list'."
  }
}

variable "alb_allow_http_80" {
  description = "If true, allow HTTP/80 to ALB (usually for redirect to HTTPS)."
  type        = bool
  default     = false
}
##################################################################################