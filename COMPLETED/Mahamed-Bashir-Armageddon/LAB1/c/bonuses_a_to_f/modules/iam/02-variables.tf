variable "region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "name_prefix" { 
  description = "The naming prefix (e.g., armageddon-lab-1c)"
  type        = string
}