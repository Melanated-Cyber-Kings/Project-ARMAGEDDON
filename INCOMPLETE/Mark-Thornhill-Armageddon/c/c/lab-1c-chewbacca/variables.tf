variable "is_lab_active" {
  description = "Set to false to destroy expensive resources (ALB, WAF, EC2) while keeping DNS/Certs."
  type        = bool
  default     = true
}
############################################
# Lab 1d_bonus-E
############################################
variable "waf_log_destination" {
  description = "Choose ONE destination per WebACL: cloudwatch | s3 | firehose"
  type        = string
  default     = "s3"
}


# Bonus variables Lab 1c_bonus-C
############################################
# Lab 1d_bonus-D
############################################
variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3."
  type        = bool
  default     = true
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs."
  type        = string
  default     = "alb-access-logs"
}

# Bonus variables Lab 1c_bonus-C
############################################
# Lab 1d_bonus-C
############################################

# Duplicate from 1c_bonus_variables.tf for simplicity in this bonus section. In real life, you'd want to avoid this duplication.
#   variable "manage_route53_in_terraform" {
#   description = "If true, create/manage Route53 hosted zone + records in Terraform."
#   type        = bool
#   default     = true
# }

# Duplicate from 1c_bonus_variables.tf for simplicity in this bonus section. In real life, you'd want to avoid this duplication.
#   variable "route53_hosted_zone_id" {
#   description = "If manage_route53_in_terraform=false, provide existing Hosted Zone ID for domain."
#   type        = string
#   default     = ""
# }
variable "aws_region" {
  description = "AWS Region for the Chewbacca fleet to patrol."
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Prefix for naming. Students should change from 'chewbacca' to their own."
  type        = string
  default     = "lew"
}

variable "vpc_cidr" {
  description = "VPC CIDR (use 10.x.x.x/xx as instructed)."
  type        = string
  default     = "10.17.0.0/16" # TODO: student supplies
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.17.1.0/24", "10.17.2.0/24"] # TODO: student supplies
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.17.11.0/24", "10.17.12.0/24"] # TODO: student supplies
}

variable "azs" {
  description = "Availability Zones list (match count with subnets)."
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"] # TODO: student supplies
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 app host."
  type        = string
  default     = "ami-03d1820163e6b9f5d" # TODO
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
  default     = "Bigpimpin6" # TODO: student supplies
}

variable "sns_email_endpoint" {
  description = "Email for SNS subscription (PagerDuty simulation)."
  type        = string
  default     = "3thornhill@gmail.com" # TODO: student supplies
}

