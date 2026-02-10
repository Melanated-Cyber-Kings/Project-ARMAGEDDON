variable "tags" {
  type = map(string)
  default = {}
}

variable "email_addresses" {
  type    = list(string)
  default = []
}
variable "sns_topic_name" {
  default = "lab-db-incidents"
}
