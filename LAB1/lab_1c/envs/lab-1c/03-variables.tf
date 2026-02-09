###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: environment
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

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
  type        = string
}

#variable "env_prefix" {
#  type        = string
#  description = "Environment prefix for naming VPC and subnets"
#}

variable "env_prefix" {
  description = "project environment"
  type        = string
  default     = "lab-1c"

  validation {
    condition     = contains(["lab-1a", "lab-1c", "lab-1c"], var.env_prefix)
    error_message = "The environment must be one of: lab-1c, lab-1c or lab-1c"
  }
}


variable "project" {
  description = "project name"
  type        = string
}

variable "avail_zone_1" {
  description = "provider region, availability zone for resources"
  type        = string
}

variable "avail_zone_2" {
  description = "provider region, availability zone for resources"
  type        = string
}

variable "public_subnet_cidr" {
  description = "public subnet cidr range"
  type        = string
}

variable "private_subnet_cidr_1" {
  description = "private subnet cidr range"
  type        = string
}

variable "private_subnet_cidr_2" {
  description = "private subnet cidr range"
  type        = string
}


variable "rtb_public_cidr" {
  description = "route table public cidr"
  type        = string
}

variable "instance_type" {
  type        = string
  description = "The type of EC2 instance to launch"
}

variable "db_name" {
  description = "Unused in env stack; value is read from Secrets Manager."
  type        = string
  default     = null
}

variable "db_username" {
  description = "Unused in env stack; credentials are pulled from Secrets Manager."
  type        = string
  default     = null
}

variable "db_password" {
  description = "Unused in env stack; credentials are pulled from Secrets Manager."
  type        = string
  default     = null
  sensitive   = true
}


variable "kms_key_arn" {
  type = string
}

variable "alert_email" {
  type = string
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS in Lab 1B."
  type        = bool

  # Set to true for Lab 1B. Set to false for troubleshooting and cost savings.
  default = false
}

variable "tags" {
  description = "Tags applied to Terraform backend resources."
  type        = map(string)
  default     = {}
}