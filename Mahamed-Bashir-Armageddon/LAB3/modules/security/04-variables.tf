variable "vpc_id"      { type = string }
variable "name_prefix" { type = string }

# Add this so the module can receive its own SG ID for rules
variable "alb_sg_id" { 
  type    = string
  default = "" 
}

variable "tcp_ingress_rule" {
  type = object({
    port        = number
    description = string
  })
}

variable "allow_remote_cidr" {
  description = "Optional: Allow a remote CIDR (e.g., Sao Paulo VPC) to access RDS via TGW"
  type        = string
  default     = null
}