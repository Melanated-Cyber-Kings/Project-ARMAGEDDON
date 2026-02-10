variable "sao_paulo_vpc_cidr" {
  description = "CIDR block of the São Paulo VPC"
  type        = string
  default     = "10.103.0.0/16"
  
}

variable "existing_vpc_id" {
  description = "ID of your EXISTING Tokyo VPC"
  type        = string
  default     = "vpc-0df1cebba33142153"  # Will be filled via .tfvars
}

variable "tokyo_vpc_cidr" {
  description = "CIDR block of Tokyo VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}


variable "existing_db_security_group_id" {
  description = "ID of your EXISTING RDS security group"
  type        = string
  default     = ""  # Will be filled via .tfvars
}

variable "existing_private_subnet_ids" {
  description = "IDs of your EXISTING private subnets for TGW attachment"
  type        = list(string)
  default     = []  # Will be filled via .tfvars
}

variable "rds_endpoint" {
  description = "Endpoint of existing Tokyo RDS (for São Paulo reference)"
  type        = string
  default     = "chewbacca-mysql.cp4248amufw3.ap-northeast-1.rds.amazonaws.com"
}

variable "db_username" {
  description = "Username for existing Tokyo RDS (for São Paulo reference)"
  type        = string
  sensitive   = true
  default     = "Tyla"
}

variable "db_password" {
  description = "Password for existing Tokyo RDS (for São Paulo reference)"
  type        = string
  sensitive   = true
  # No default - must be provided in .tfvars
}

variable "sao_paulo_peering_attachment_id" {
  description = "São Paulo TGW peering attachment ID to accept"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "tokyo_tgw_id" {
  description = "Tokyo Transit Gateway ID"
  type        = string
}

variable "tokyo_tgw_route_table_id" {
  description = "Tokyo TGW Route Table ID"
  type        = string
}

# Add any other variables you see in terraform.tfvars
# Check with: cat terraform.tfvars