###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: VPC Endpoints Variables
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for interface endpoints"
}

variable "private_route_table_id" {
  type        = string
  description = "Private route table ID for S3 gateway endpoint"
}

variable "endpoint_sg_id" {
  type        = string
  description = "Security group ID to attach to interface endpoints ENIs"
}


variable "region" {
  type        = string
  description = "AWS region"
}

variable "enable_kms_endpoint" {
  type        = bool
  description = "Whether to create a KMS interface endpoint"
  default     = false
}
