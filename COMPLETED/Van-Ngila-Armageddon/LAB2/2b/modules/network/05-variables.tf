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

variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3"
  type        = bool
  default     = true
}

variable "alb_access_logs_bucket_name" {
  description = "Name of S3 bucket for ALB access logs"
  type        = string
  #default = "lab-1c-alb-logs-031857855861"
}

variable "alb_access_logs_bucket_arn" {
  description = "ARN of S3 bucket for ALB access logs"
  type        = string
  #default = "arn:aws:s3:::lab-1c-alb-logs-031857855861"
}

variable "alb_logs_bucket_dependency" {
  description = "Dependency reference to S3 bucket for ALB"
  type        = any
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs"
  type        = string
  default     = "alb-access-logs"
}

variable "shinjuku_origin_header_value01_result" {
  type = string
}