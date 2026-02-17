variable "name_prefix" {  
  description = "The naming prefix"
  type        = string
}
variable "vpc_id" { 
    type = string 
    }
variable "public_subnet_ids" { 
    type = list(string) 
    }
variable "security_group_ids" { 
    type = list(string) 
    }
variable "target_id" { 
    type = string 
    }

variable "certificate_arn" {
  description = "ACM Certificate ARN for HTTPS"
  type        = string
}

variable "access_logs_bucket" {
  description = "S3 Bucket ID for Access Logs"
  type        = string
}