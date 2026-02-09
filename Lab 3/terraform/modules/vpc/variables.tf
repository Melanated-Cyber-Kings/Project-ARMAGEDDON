variable "region_name" {
  description = "Name of the region (e.g., shinjuku, liberdade)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Map of public subnet CIDR blocks"
  type        = map(string)
  default     = {}
}

variable "private_subnet_cidrs" {
  description = "Map of private subnet CIDR blocks"
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
