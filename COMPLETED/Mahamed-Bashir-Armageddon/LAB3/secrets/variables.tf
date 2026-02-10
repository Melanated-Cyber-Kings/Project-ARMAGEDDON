variable "active_missions" {
  description = "List of active lab environments requiring secrets"
  type        = list(string)
  default     = ["lab-3"] # Add more as you progress
}

variable "region" {
  type = string
  default = "ap-northeast-1"
}