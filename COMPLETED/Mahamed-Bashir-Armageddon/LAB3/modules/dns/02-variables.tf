variable "domain_name" {   
    type = string 
    }
variable "name_prefix" { 
    type = string 
    }

# Target Coordinates
variable "alias_dns_name" { 
    type = string 
    }
variable "alias_zone_id"  { 
    type = string 
    }

# ACM Bridge
variable "domain_validation_options" {
  description = "Validation options from the ACM certificate"
  type        = any
}