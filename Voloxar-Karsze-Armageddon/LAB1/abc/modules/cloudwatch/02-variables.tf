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

variable region {
  type = string
}

variable "alert_email" {
  type = string
}

#####bonus stuff####
variable "alb_5xx_threshold" {
  description = "Alarm threshold for ALB 5xx count."
  type        = number
  default     = 10
}

variable "alb_5xx_period_seconds" {
  description = "CloudWatch alarm period."
  type        = number
  default     = 300
}

variable "alb_5xx_evaluation_periods" {
  description = "Evaluation periods for alarm."
  type        = number
  default     = 1
}

variable arn_suffix{
  type = string
}



###usual crap###
variable "env_prefix" {
  type = string
}

variable "project" {
  type = string
}