variable "region" {
  type        = string
  description = "The AWS region to deploy resources in"
  default     = "ap-northeast-1"
}

variable "aws_region" {
  description = "AWS region (alias for compatibility)"
  type        = string
  default     = "ap-northeast-1"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC cidr block"
  type = string
  default = "172.17.0.0/16"
}

variable "env_prefix" {
  description = "project environment"
  type = string
  default = "lab-1a"

  validation {
    condition = contains(["lab-1a", "lab-1b", "lab-1c"], var.env_prefix)
      error_message = "The environment must be one of: lab-1a, lab-1b or lab-1c"
  }
}

variable "project" {
  description = "project name"
  type = string
  default = "Armageddon"
}

# For HA: Change single AZ to list of AZs
variable "availability_zones" {
  description = "Availability zones for High Availability"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1b"]
}

# For HA: Change single subnet to list of subnets
variable "public_subnet_cidrs" {
  description = "Public subnet cidr ranges (list for HA)"
  type        = list(string)
  default     = ["172.17.1.0/24", "172.17.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet cidr ranges (list for HA)"
  type        = list(string)
  default     = ["172.17.11.0/24", "172.17.12.0/24"]
}

variable "rtb_public_cidr" {
  description = "route table public cidr"
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  type        = string
  description = "The type of EC2 instance to launch"
  default     = "t3.micro"
}

# NEW VARIABLES NEEDED
variable "student_name" {
  description = "Student name for tagging"
  type        = string
  default     = "Cameron-Cleveland"
}

variable "db_password" {
  description = "RDS database password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "labdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "Allowed SSH CIDR blocks"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_cidr" {
  description = "Allowed HTTP CIDR blocks"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Keep old variables for backward compatibility
variable "avail_zone" {
  description = "Legacy: Single availability zone"
  type        = string
  default     = "ap-northeast-1a"
}

variable "public_subnet_cidr" {
  description = "Legacy: Single public subnet CIDR"
  type        = string
  default     = "172.17.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Legacy: Single private subnet CIDR"
  type        = string
  default     = "172.17.11.0/24"
}
