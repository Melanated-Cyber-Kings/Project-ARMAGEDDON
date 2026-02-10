variable "target_group_arn" {
  type = string
}

variable "env_prefix" {
  type = string
}

variable "project" {
  type = string
}

variable "vpc_id" {
  description = "VPC ID where the RDS security group is created"
  type        = string
}

variable "certificate_arn" {
  type = string
}

variable alb_sg_id{
  type = string
}

variable public_subnet_ids {
  type = list(string)
}

#for the alb, lab2
variable header_value{
  type = string
}



#turn on waf?
variable enable_waf {
  type = bool
  default = true
}

#turn on alb logs --> s3?
variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3."
  type        = bool
  default     = true
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs."
  type        = string
  default     = "alb-access-logs-s3"
}

variable alb_access_logs_bucket_name {
  type = string
  default = "alb01-bucket"
}

variable waf_log_destination {
  type = string
  default = "cloudwatch"
}

variable waf_log_retention_days {  
  type    = number  
  default = 7
}