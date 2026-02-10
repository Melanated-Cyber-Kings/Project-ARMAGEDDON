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

variable "tags" {
  description = "Common tags applied to all resources in this lab."
  type        = map(string)
  default     = {}
}

