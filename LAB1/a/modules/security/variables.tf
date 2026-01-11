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