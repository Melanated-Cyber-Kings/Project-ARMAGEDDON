variable "region" {
  description = "AWS region"
  type        = string
}

variable "env_prefix" {
  type = string
}

variable "private_subnet_ids" {
    type = list
}

variable "lambda_security_group_ids" {
    type = list
}

variable "secret_id" {
    type = string
}