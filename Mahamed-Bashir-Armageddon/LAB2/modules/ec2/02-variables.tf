variable "subnet_id" {
  type = string
}

variable "region" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "name_prefix" {  
  type        = string
}

variable "security_group_ids" {
  type        = list(string)
}

variable "instance_profile_name" {
  type        = string
}

variable "user_data" {
  description = "Startup script for the EC2"
  type        = string
  default     = null 
}

variable "public_ip" {
  type        = bool
  default     = false
}