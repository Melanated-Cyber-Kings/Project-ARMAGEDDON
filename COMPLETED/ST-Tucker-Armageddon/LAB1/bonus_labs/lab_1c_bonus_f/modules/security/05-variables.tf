###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: security
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
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

# RDS MySQL access from EC2 security group
# Defines the TCP ingress rule for allowing EC2 instances to access RDS MySQL database.

variable "tcp_ingress_rule" {
  description = "RDS MySQL access from EC2 security group"
  type = object({
    port        = number
    description = string
  })

  # Default: MySQL port 3306 access from EC2 instances
  # if not specified.

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
  #default     = 80
}

variable "tags" {
  description = "Common tags applied to all resources in this lab."
  type        = map(string)
  default     = {}
}

