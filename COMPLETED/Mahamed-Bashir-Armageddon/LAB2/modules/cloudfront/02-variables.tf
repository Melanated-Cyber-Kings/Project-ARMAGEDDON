variable "name_prefix" { 
  type = string 
  }
variable "domain_name" { 
  type = string 
  }
variable "alb_dns_name" { 
  type = string 
  }
variable "waf_acl_id"  { 
  type = string 
  }
variable "acm_cert_arn" { 
  type = string 
  }

variable "secret_header_name"  { 
  type = string 
  }
variable "secret_header_value" { 
  type = string 
  }

  variable "log_bucket_name" {
  type        = string
}