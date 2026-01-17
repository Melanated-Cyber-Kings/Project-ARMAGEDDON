variable "env_prefix" {
  description = "Environment prefix"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
}

# NEW: Lists for HA
variable "availability_zones" {
  description = "Availability zones for HA deployment"
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks for HA"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks for HA"
  type        = list(string)
  default     = []
}

# OLD: Single values (for backward compatibility)
variable "avail_zone" {
  description = "Single availability zone (legacy)"
  type        = string
  default     = ""
}

variable "public_subnet_cidr" {
  description = "Single public subnet CIDR (legacy)"
  type        = string
  default     = ""
}

variable "private_subnet_cidr" {
  description = "Single private subnet CIDR (legacy)"
  type        = string
  default     = ""
}

variable "rtb_public_cidr" {
  description = "Public route table CIDR"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}
