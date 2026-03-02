variable "subnet_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "env_prefix" {
  type = string
}

# ec2/variables.tf
variable "security_group_ids" {
  description = "List of security group IDs to attach to EC2 instance"
  type        = list(string)
}

variable "instance_profile_name" {
  description = "IAM instance profile name for EC2"
  type        = string
}