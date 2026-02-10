variable "sns_topic_name" {
  default = "lab-db-incidents"
}

variable "email_addresses" {
  type    = list(string)
  default = []
}

variable "log_group_name" {
  default = "/aws/ec2/lab-rds-app"
}

variable "log_retention_days" {
  default = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}