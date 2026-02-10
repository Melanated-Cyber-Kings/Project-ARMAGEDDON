variable "vpc_id" {
  description = "VPC ID where the RDS security group is created"
  type        = string
}

variable "env_prefix" {
  type = string
}

variable "project" {
  type = string
}

variable "ec2_id" {
    type = string
}