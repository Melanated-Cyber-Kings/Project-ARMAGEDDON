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
  description = "The naming prefix (e.g., armageddon-lab-1c)"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to EC2 instance"
  type        = list(string)
}

variable "instance_profile_name" {
  description = "IAM instance profile name for EC2"
  type        = string
}

variable "user_data" {
  description = "Startup script for the EC2 instance"
  type        = string
  default     = null 
}

variable "public_ip" {
  description = "Assign Public IP? (False for Bonus A)"
  type        = bool
  default     = false
}