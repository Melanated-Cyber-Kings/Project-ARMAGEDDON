################# VPC & NETWORKING #################
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
variable "public_subnet_cidr" {
  description = "public subnet cidr range"
  type = string
}
############################################################
variable "private_subnet_cidr_1" {
  description = "private subnet cidr range"
  type = string
}
############################################################
variable "private_subnet_cidr_2" {
  description = "CIDR for the second private subnet"
  type        = string
}
############################################################
variable "avail_zone_2" {
  description = "Second AZ for high availability"
  type        = string
}
############################################################
variable "avail_zone" {
    description = "availability zones for subnets"
    type = string
}
############################################################
variable "rtb_public_cidr" {
  description = "route table public cidr"
  type = string
}
############################################################
variable "name_prefix" {
  description = "project environment"
  type = string
}