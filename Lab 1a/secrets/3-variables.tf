variable "region" {
  type        = string
  description = "The AWS region to deploy resources in"
}

variable "env_prefix" {
  description = "project environment"
  type = string
  #default = "lab-1a"
}
