################# VPC & NETWORKING PHASE-1 #################
variable "vpc_cidr_block" {
  description = "VPC cidr block"
  type = string
}
############################################################
variable "dns_hostnames" {
  description = "boolean for private dns hostnames for vpc"
  type = bool
  default = true
}
############################################################
variable "dns_support" {
  description = "boolean for private dns for vpc"
  type = bool
  default = true
}
############################################################
variable "env_prefix" {
  type        = string
  description = "Environment prefix for naming VPC and subnets"
}
############################################################
variable "public_subnet_cidr_1" {
  description = "public subnet cidr range"
  type = string
}

variable "public_subnet_cidr_2" {
  description = "public subnet cidr range"
  type = string
}
############################################################
variable "private_subnet_cidr_1" {
  description = "private subnet cidr range"
  type = string
}

variable "private_subnet_cidr_2" {
  description = "private subnet cidr range"
  type = string
}

variable "private_subnet_cidr_3" {
  description = "private subnet cidr range"
  type = string
}
############################################################
variable "avail_zone_1" {
    description = "availability zones for subnets"
    type = string
}

variable "avail_zone_2" {
    description = "availability zones for subnets"
    type = string
}

variable "avail_zone_3" {
    description = "availability zones for subnets"
    type = string
}
############################################################
variable "rtb_public_cidr" {
description = "route table public cidr"
 type = string
}
############################################################
#Bonus
variable "certificate_validation_method" {
  description = "ACM validation method. Students can do DNS (Route53) or EMAIL."
  type        = string
  default     = "DNS"
}

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "theowafhomework.site"
}

variable "app_subdomain" {
  description = "Subdomain for the application"
  type        = string
  default     = "app"  # Will create app.theowafhomework.site
}

variable "alb_sg_id" {
  type = string
}

variable "ec2_id" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

# variable "acm_certificate_validation_id" {
#   description = "ID of the ACM certificate validation to depend on"
#   type        = string
#   #default     = ""
# }