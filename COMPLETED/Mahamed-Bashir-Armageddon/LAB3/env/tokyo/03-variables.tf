# ---  METADATA ---
variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "env_prefix" {
  description = "Mission identifier"
  type        = string
  default     = "lab-2a"
}

variable "region" {
  description = "The primary AWS region for infrastructure"
  type        = string
}

variable "account_id" {
  description = "The AWS Account ID"
  type        = string
}

# --- EDGE & IDENTITY ---
variable "domain_name" {
  description = "The FQDN"
  type        = string
}

variable "db_secret_name" {
  description = "The name of the secret"
  type        = string
}

# --- NETWORKING & COMPUTE ---
variable "vpc_cidr_block" {
  description = "CIDR range for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR list for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs_app" {
  description = "CIDR list for private app subnets"
  type        = list(string)
}

variable "private_subnet_cidrs_db" {
  description = "CIDR list for private db subnets"
  type        = list(string)
}

variable "avail_zones" {
  description = "Availability zones to use"
  type        = list(string)
}

variable "rtb_public_cidr" {
  description = "Public route destination"
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
}

variable "sns_email" {
  description = "Email endpoint"
  type        = string
}

variable "us_east_1_acm_arn" {
  description = "The ARN of the ACM certificate created in us-east-1"
  type        = string
}

variable "remote_spoke_cidr"          { 
  type = string 
  description = "CIDR block of remote hub VPC for peering"
  }
