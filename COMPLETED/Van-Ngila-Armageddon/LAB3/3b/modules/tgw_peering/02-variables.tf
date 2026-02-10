variable "requester_name" {
  description = "Name for the requester side peering attachment"
  type        = string
}

variable "accepter_name" {
  description = "Name for the accepter side peering attachment"
  type        = string
}

variable "requester_tgw_id" {
  description = "Transit Gateway ID on requester side (Tokyo)"
  type        = string
}

variable "accepter_tgw_id" {
  description = "Transit Gateway ID on accepter side (São Paulo)"
  type        = string
}

variable "requester_region" {
  description = "AWS region for requester side"
  type        = string
}

variable "accepter_region" {
  description = "AWS region for accepter side"
  type        = string
}

variable "peer_account_id" {
  description = "AWS Account ID of the peer (same account for Lab 3A)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}