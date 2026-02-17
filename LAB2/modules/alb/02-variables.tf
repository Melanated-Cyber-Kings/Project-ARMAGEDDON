variable "name_prefix"        { 
    type = string 
    }
variable "vpc_id"             { 
    type = string 
    }
variable "public_subnet_ids"  { 
    type = list(string) 
    }
variable "security_group_ids" { 
    type = list(string) 
    }
variable "target_id"          { 
    type = string 
    }
variable "access_logs_bucket" { 
    type = string 
    }
variable "certificate_arn"    { 
    type = string 
    }

variable "https_listener_arn" { 
    type = string 
    }
variable "target_group_arn"   { 
    type = string 
    }
variable "header_name"        { 
    type = string 
    }
variable "header_value"       { 
    type = string 
    }