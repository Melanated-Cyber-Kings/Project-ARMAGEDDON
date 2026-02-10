variable "name" {
  description = "Name of the TGW VPC Attachment"
  type        = string
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to attach"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to attach"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "appliance_mode_support" {
  description = "Whether Appliance Mode support is enabled"
  type        = string
  default     = "disable"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}