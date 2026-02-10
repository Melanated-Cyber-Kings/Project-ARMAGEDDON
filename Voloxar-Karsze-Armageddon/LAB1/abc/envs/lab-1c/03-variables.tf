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

#variable "env_prefix" {
#  type        = string
#  description = "Environment prefix for naming VPC and subnets"
#}

variable "env_prefix" {
  description = "project environment"
  type = string
  default = "lab"

  # validation {
  #   condition = contains(["lab-1a", "lab-1b", "lab-1c"], var.env_prefix)
  #     error_message = "The environment must be one of: lab-1b, lab-1b or lab-1c"
  # }
}


variable "project" {
  description = "project name"
  type = string
}

variable "avail_zone_1" {
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

variable "public_subnet_cidr2" {
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
  description = "DB master username (students should use Secrets Manager in 1B/1C)."
  type        = string
}

variable "db_password" {
  description = "DB master password (DO NOT hardcode in real life; for lab only)."
  type        = string
  sensitive   = true
}


variable "kms_key_arn" {
  type = string
}

variable "alert_email" {
  type = string
  default =""
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "domain_name" {
  type    = string
  default = "example.com"
}

variable "app_subdomain" {
  type = string
  default = "app1"
}


#for zone 53 policy stuff
#override with export TF_VAR_aws_cli_username="$(aws iam get-user --query 'User.UserName' --output text)"
variable "aws_cli_username" {
  type = string
  default = "AWSCLI"
}

variable enable_alb_logs {
  default = true
}