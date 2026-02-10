variable "region" {
  type        = string
  description = "The AWS region to deploy resources in"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}



variable "vpc_cidr_block" {
  description = "VPC cidr block"
  type = string
}


variable "name_prefix" {
  description = "lab environment full name"
  type = string
}

variable "env_prefix" {
  description = "environment prefix"
  type = string
  
}
variable "project" {
  description = "project name"
  type = string
}

variable "avail_zone" {
    description = "provider region, availability zone for resources"
    type = string
}

variable "avail_zone_2" {
    description = "provider region, availability zone for resources"
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


variable "sns_email" {
  description = "Email address for alarm notifications"
  type        = string
}