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

variable "rds_host" {
  description = "RDS endpoint"
  type        = string
}

variable "secret_id" {
  description = "Secrets Manager secret ID"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "user_data_path" {
  description = "Path to EC2 user_data script"
  type        = string
}
