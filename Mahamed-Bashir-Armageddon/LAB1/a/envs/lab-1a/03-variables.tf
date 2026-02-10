variable "region" {
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}


variable "vpc_cidr_block" {
  description = "VPC cidr block"
  type = string
}

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

variable "avail_zone_1" {
    type = string
}

variable "avail_zone_2" {
    type = string
}

variable "public_subnet_cidr" {
  description = "public subnet cidr range"
  type = string
}

variable "private_subnet_cidr_1" {
  description = "private subnet cidr range"
  type = string
}

variable "private_subnet_cidr_2" {
  description = "private subnet cidr range"
  type = string
}


variable "rtb_public_cidr" {
  description = "route table public cidr"
  type = string
}

variable "instance_type" {
  type        = string
  description = "The type of EC2 instance to launch"
} 

variable "db_name" {
  description = "Initial database name."
  type        = string
}

variable "db_username" {
  type        = string
}

variable "db_password" {
  type        = string
  sensitive   = true
}


variable "kms_key_arn" {
  type = string
}