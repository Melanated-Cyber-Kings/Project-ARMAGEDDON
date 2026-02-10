variable "region_name" {
  description = "Name of the region (e.g., tokyo, sao-paulo)"
  type        = string
}
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}
variable "availability_zones" {
  description = "List of AZs to use"
  type        = list(string)
}
variable "public_cidr_blocks" {
  description = "Map of public subnet CIDRs"
  type        = map(string)
}
variable "private_cidr_blocks" {
  description = "Map of private subnet CIDRs"
  type        = map(string)
  default     = {} # São Paulo might not have private subnets
}
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
variable "is_tokyo" {
  description = "Flag to enable Tokyo-specific resources (like DB subnets)"
  type        = bool
  default     = false
}
