variable "vpc_id" {
  description = "ID of the VPC"
  type = string
}

variable "private_subnet_ids" {
    type = list
    description = "ID of the private subnets together"
}

variable "region" {
    type = string
}

variable "tgw_attach_id" {
    type = string
}

variable "private_route_table_id" {
    type = string
}

variable "dest_cidr_block" {
    type = string
}