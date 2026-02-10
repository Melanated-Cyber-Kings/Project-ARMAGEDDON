###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: VPC Endpoints Variables
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
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

variable "ec2_sg_id" {
  type        = string
  description = "EC2 security group ID; used to allow 443 into endpoint ENIs"
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
# New variable to accept security group IDs for VPC endpoints
variable "vpce_security_group_ids" {
  description = "Security group IDs to associate with interface VPC endpoints"
  type        = list(string)
}
