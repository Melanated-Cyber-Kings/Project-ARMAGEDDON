variable "bucket_name" {
  description = "The globally unique name of the bucket"
  type        = string
}

variable "force_destroy" {
  description = "Allow destruction of non-empty buckets"
  type        = bool
  default     = true
}

variable "versioning_status" {
  description = "Enabled or Suspended"
  type        = string
  default     = "Suspended" 
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Environment prefix for naming"
  type        = string
}