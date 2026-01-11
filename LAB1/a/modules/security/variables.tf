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
  description = "tcp ingress in security group sg-rds-lab1a"
  type = object({
      cidr = string
      port = number
      description = string
  })
  default = {
    cidr = "172.17.0.0/16"
    port = 3306
    description = "tcp ingress rule"
  }
}