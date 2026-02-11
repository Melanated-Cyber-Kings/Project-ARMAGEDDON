################# VPC & NETWORKING#################
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
variable "public_subnet_cidrs" {
  type = list(string)
}
############################################################

variable "private_subnet_cidrs_app" {
  type = list(string)
}

############################################################

variable "private_subnet_cidrs_db" {
  type = list(string)
}
############################################################

variable "azs" {
  type = list(string)
}
############################################################
variable "rtb_public_cidr" {
  description = "route table public cidr"
  type = string
}
############################################################
variable "name_prefix" {  
  description = "The naming prefix"
  type        = string
}