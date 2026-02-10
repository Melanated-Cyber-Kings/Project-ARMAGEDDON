variable "name_prefix" {
  description = "Prefix for naming resources (e.g., project-env)"
  type        = string
}

variable "log_group_name" {
  description = "The name of the CloudWatch Log Group to create/monitor"
  type        = string
}

variable "retention_days" {
  description = "How long to keep logs in days"
  type        = number
  default     = 14
}

variable "filter_pattern" {
  description = "The text pattern to look for in the logs (e.g., 'ERROR')"
  type        = string
}

variable "metric_name" {
  description = "The name of the custom metric to increment"
  type        = string
}

variable "metric_namespace" {
  description = "The namespace for the custom metric"
  type        = string
}

variable "threshold" {
  description = "The number of errors required to trigger the alarm"
  type        = number
  default     = 3
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers (e.g., SNS Topic ARN)"
  type        = list(string)
}