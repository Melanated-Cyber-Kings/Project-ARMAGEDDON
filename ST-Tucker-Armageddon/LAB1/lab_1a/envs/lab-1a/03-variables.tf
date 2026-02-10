###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: environment
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

# -------------------------------------------------
# LAB 1A — Environment Variables
# -------------------------------------------------

# -----------------
# AWS / Project
# -----------------

variable "region" {
  type        = string
  description = "AWS region to deploy resources into."
}

variable "project" {
  type        = string
  description = "Project name (used for tagging and naming)."
}

variable "env_prefix" {
  type        = string
  description = "Environment prefix (e.g., lab-1a)."
}

variable "account_id" {
  type        = string
  description = "AWS account ID."
}

# -----------------
# Networking
# -----------------

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet."
}

variable "private_subnet_cidr_1" {
  type        = string
  description = "CIDR block for private subnet 1."
}

variable "private_subnet_cidr_2" {
  type        = string
  description = "CIDR block for private subnet 2."
}

variable "avail_zone_1" {
  type        = string
  description = "Availability Zone for subnet 1."
}

variable "avail_zone_2" {
  type        = string
  description = "Availability Zone for subnet 2."
}

variable "rtb_public_cidr" {
  type        = string
  description = "CIDR route for public route table (usually 0.0.0.0/0)."
}

# -----------------
# EC2
# -----------------

variable "instance_type" {
  type        = string
  description = "EC2 instance type."
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access (optional)"
  type        = string
  default     = null
}


# -----------------
# RDS / Secrets
# -----------------

variable "db_secret_name" {
  type        = string
  description = "Secrets Manager secret name containing DB credentials JSON."
  default     = "lab-1a/rds/mysql"
}

variable "db_port" {
  type        = number
  description = "Database port allowed from EC2 to RDS."
  default     = 3306
}

# -----------------
# IAM / KMS
# -----------------

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN used to encrypt/decrypt the Secrets Manager secret."
}
