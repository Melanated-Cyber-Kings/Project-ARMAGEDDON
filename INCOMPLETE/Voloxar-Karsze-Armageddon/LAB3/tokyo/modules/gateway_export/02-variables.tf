#lab3
variable "peer_tgw_id" {
  type = string
}

variable "tgw_attach_id" {
  type = string
}

variable "region" {
  type        = string
  description = "The AWS region to deploy resources in"
}

variable "sao_vpc_id" {
  type = string
}