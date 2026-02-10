variable "region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "name_prefix" {  # <--- THIS IS THE KEY
  description = "The naming prefix (e.g., armageddon-lab-1c)"
  type        = string
}