variable "vpc_id" {
  description = "VPC ID where the RDS security group is created"
  type        = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "env_prefix" {
  type = string
}

# stolen from ec2/variables.tf
variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

#this may end up being a list in the future?
variable "private_route_table_id" {
  description = "ID of the private route table"
  type = string
}

variable "secrets_lambda_sg_id" {
  description = "List of security group IDs"
  type        = string
}