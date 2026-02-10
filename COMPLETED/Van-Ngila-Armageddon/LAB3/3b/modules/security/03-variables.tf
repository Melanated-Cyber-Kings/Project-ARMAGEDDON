variable "vpc_id" {
  description = "VPC ID where the RDS security group is created"
  type        = string
}

variable "env_prefix" {
  type = string
}


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

variable "vpc_endpoint_sg_id" {
  description = "Security group ID for VPC interface endpoints"
  type        = string
  default     = ""
  
  # validation {
  #   condition     = length(var.vpc_endpoint_sg_id) > 0
  #   error_message = "VPC endpoint security group ID is required for interface endpoints."
  # }
}

variable "saopaulo_vpc_cidr" {
  description = "São Paulo VPC CIDR for cross-region RDS access"
  type        = string
}
