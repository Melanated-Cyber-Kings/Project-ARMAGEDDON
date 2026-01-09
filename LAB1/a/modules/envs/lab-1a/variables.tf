variable "region" {
  type        = string
  description = "The AWS region to deploy resources in"
}



variable "vpc_cidr_block" {
  description = "VPC cidr block"
  type = string
}

#variable "env_prefix" {
#  type        = string
#  description = "Environment prefix for naming VPC and subnets"
#}

variable "env_prefix" {
  description = "project environment"
  type = string
  default = "lab-1a"

  validation {
    condition = contains(["lab-1a", "lab-1b", "lab-1c"], var.env_prefix)
      error_message = "The environment must be one of: lab-1a, lab-1b or lab-1c"
  }
}


variable "project" {
  description = "project name"
  type = string
}

variable "avail_zone" {
    description = "provider region, availability zone for resources"
    type = string
}

variable "public_subnet_cidr" {
  description = "public subnet cidr range"
  type = string
}

variable "private_subnet_cidr" {
  description = "private subnet cidr range"
  type = string
}

variable "rtb_public_cidr" {
  description = "route table public cidr"
  type = string
}