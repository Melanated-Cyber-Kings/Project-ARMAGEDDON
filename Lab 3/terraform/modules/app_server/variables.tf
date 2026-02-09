variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}  # Make it optional with empty default
}

variable "iam_instance_profile" {
  description = "IAM instance profile name for SSM access"
  type        = string
  default     = ""  # Make optional
}

# Add to your existing modules/app_server/variables.tf:

variable "rds_endpoint" {
  description = "RDS endpoint for database connection"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}