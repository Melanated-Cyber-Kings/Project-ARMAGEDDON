variable "active_missions" {
  description = "List of active lab environments requiring secrets"
  type        = list(string)
  default     = ["Lab-1c", "Lab-2a", "Lab-2b"]
}

variable "region" {
  type = string
  default = "ap-northeast-1"
}