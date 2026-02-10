variable "tokyo_vpc_cidr" {
  description = "CIDR block of Tokyo VPC"
  type        = string
  default     = "10.100.0.0/16"
}
variable "aws_region" {
  description = "AWS region for São Paulo"
  type        = string
  default     = "sa-east-1"
}

/*variable "tokyo_tgw_id" {
  description = "ID of Tokyo Transit Gateway"
  type        = string
}

variable "tokyo_tgw_route_table_id" {
  description = "ID of Tokyo TGW Route Table"
  type        = string
}*/

# Add these variables to your existing saopaulo/variables.tf

variable "rds_endpoint" {
  description = "Tokyo RDS endpoint for database connection"
  type        = string
  sensitive   = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "db_username" {
  description = "Database username for Tokyo RDS"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password for Tokyo RDS"
  type        = string
  sensitive   = true
}

variable "sao_paulo_vpc_cidr" {
  description = "CIDR block for São Paulo VPC"
  type        = string
  default     = "10.103.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones for São Paulo"
  type        = list(string)
  default     = ["sa-east-1a", "sa-east-1c"]
}

variable "tokyo_tgw_id" {
  description = "Tokyo Transit Gateway ID"
  type        = string
}

variable "tokyo_tgw_route_table_id" {
  description = "Tokyo TGW Route Table ID"
  type        = string
}