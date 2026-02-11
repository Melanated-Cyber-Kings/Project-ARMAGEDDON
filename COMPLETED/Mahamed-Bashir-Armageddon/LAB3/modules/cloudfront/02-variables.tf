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

# HANDSHAKE NAMES
variable "secret_header_name"  { 
  type = string 
  }
variable "secret_header_value" { 
  type = string 
  }

  variable "log_bucket_name" {
  description = "The S3 bucket name for CloudFront standard logs"
  type        = string
}

variable "secondary_alb_dns_name" {
  description = "Optional: The DNS name of the Secondary Region ALB (e.g., Sao Paulo)"
  type        = string
  default     = null 
}