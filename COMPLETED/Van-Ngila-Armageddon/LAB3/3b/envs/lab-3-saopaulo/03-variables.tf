# São Paulo variables
variable "aws_profile" {
  description = "AWS CLI profile name"
  type        = string
  default     = "default"
}

variable "saopaulo_vpc_cidr" {
  description = "CIDR block for São Paulo VPC"
  type        = string
  default     = "172.18.0.0/16"
}

variable "public_subnet_cidr_1" {
  description = "CIDR for first public subnet in São Paulo"
  type        = string
  default     = "172.18.1.0/24"
}

variable "public_subnet_cidr_2" {
  description = "CIDR for second public subnet in São Paulo"
  type        = string
  default     = "172.18.2.0/24"
}

variable "private_subnet_cidr_1" {
  description = "CIDR for first private subnet in São Paulo"
  type        = string
  default     = "172.18.11.0/24"
}

variable "private_subnet_cidr_2" {
  description = "CIDR for second private subnet in São Paulo"
  type        = string
  default     = "172.18.12.0/24"
}

variable "private_subnet_cidr_3" {
  description = "CIDR for third private subnet in São Paulo"
  type        = string
  default     = "172.18.13.0/24"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "lab"
    Terraform   = "true"
    Lab         = "3A"
  }
}

# EC2 configuration
variable "instance_type" {
  description = "EC2 instance type for São Paulo"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for São Paulo (leave empty for latest Amazon Linux 2)"
  type        = string
  default     = ""
}