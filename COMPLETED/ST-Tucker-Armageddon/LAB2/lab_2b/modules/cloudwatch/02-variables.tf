###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: cloudwatch
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

# variable "sns_topic_name" {
#   default = "lab-db-incidents"
# }

# variable "email_addresses" {
#   type    = list(string)
#   default = []
# }
# variable "alert_email" {
#   description = "Email address to subscribe to the SNS incident notification topic"
#   type        = string
# }

# variable "log_group_name" {
#   default = "/aws/ec2/lab-rds-app"
# }

# variable "log_retention_days" {
#   default = 7
# }

# variable "tags" {
#   type    = map(string)
#   default = {}
# }

variable "sns_topic_name" {
  default = "lab-db-incidents"
}

variable "email_addresses" {
  type        = list(string)
  default     = []
  description = "Email addresses to subscribe to the SNS incident notification topic"
}

variable "log_group_name" {
  default = "/aws/ec2/lab-rds-app"
}

variable "log_retention_days" {
  default = 7
}

variable "tags" {
  description = "Tags applied to Terraform backend resources."
  type        = map(string)
  default     = {}
}
