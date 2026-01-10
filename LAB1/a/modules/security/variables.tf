variable "env_prefix" {
  description = "Naming prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where security groups will be created"
  type        = string
}

variable "all_ips" {
  description = "CIDR block for the whole internet"
  type        = list(string)
}

variable "any_port" {
  description = "Port number representing 'any' port"
  type        = number
}

variable "any_protocol" {
  description = "Protocol string representing 'any' protocol"
  type        = string
}

# The Dynamic Rule Set
variable "ec2_ingress_rules" {
  description = "List of ingress rules for the EC2 Security Group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}


variable "db_port" {
  description = "Port for Database"
  type        = number
}