variable "aws_region" {
  description = "AWS Region."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for naming convention."
  type        = string
  default     = "armageddon-class7"
}

variable "vpc_cidr" {
  description = "VPC CIDR."
  type        = string
  default     = "172.17.0.0/16" # Melenated Cyber Kings
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs."
  type        = list(string)
  default     = ["172.17.1.0/24", "172.17.2.0/24"] # Melenated Cyber Kings
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["172.17.101.0/24", "172.17.102.0/24"] # Melenated Cyber Kings
}

variable "azs" {
  description = "Availability Zones list (match count with subnets)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"] # Melenated Cyber Kings
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 app host."
  type        = string
  default     = "ami-0bdd88bd06d16ba03" # TODO
}

variable "ec2_instance_type" {
  description = "EC2 instance size for the app."
  type        = string
  default     = "t3.micro"
}

variable "db_engine" {
  description = "RDS engine."
  type        = string
  default     = "mysql"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "labdb" # Students can change
}

variable "db_username" {
  description = "DB master username (students should use Secrets Manager in 1B/1C)."
  type        = string
  default     = "admin" # TODO: student supplies
}

variable "db_password" {
  description = "DB master password (DO NOT hardcode in real life; for lab only)."
  type        = string
  sensitive   = true
  default     = "yomommadontwearnodraws" # TODO: student supplies
}

variable "sns_email_endpoint" {
  description = "Email for SNS subscription (PagerDuty simulation)."
  type        = string
  default     = "edafe.usa@gmail.com" # TODO: student supplies
}

variable "secret_name" {
  description = "Email for SNS subscription (PagerDuty simulation)."
  type        = string
  default     = "dakid/lab/rds/mysql" # TODO: student supplies
}




