variable "vpc_id"      { type = string }
variable "name_prefix" { type = string }

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
  description = "Allow a remote CIDR (e.g., Sao Paulo VPC) to access RDS via TGW"
  type        = string
  default     = null
}