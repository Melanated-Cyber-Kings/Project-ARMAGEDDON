variable "name_prefix"           { 
    type = string 
    }
variable "vpc_id"                { 
    type = string 
    }
variable "subnet_ids"            { 
    type = list(string) 
    }
variable "is_requester"          { 
    type = bool 
    }
variable "peer_region"           { 
    type = string
    default = null 
    }
variable "peer_tgw_id"           { 
    type = string
    default = null 
    }
variable "peering_attachment_id" { 
    type = string 
    default = null 
    }

variable "remote_cidr" {
  description = "The CIDR of the remote region to route through the peering"
  type        = string
  default     = null
}