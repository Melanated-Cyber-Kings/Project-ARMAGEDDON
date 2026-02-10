variable "vpc_id" {
  description = "ID of the VPC"
  type = string
}

variable "private_subnet_ids" {
    type = list
    description = "ID of the private subnets together"
}

variable "peer_transitgw_id" {
  type = string
  description = "ID of peer transit gateway"
}

variable "private_route_table_id" {
    type = string
}

variable "dest_cidr_block" {
    type = string
}