variable "region" {
  type        = string
  description = "The AWS region to deploy resources in"
}
###############################################################
variable "account_id" {
  description = "AWS account ID"
  type        = string
}
##############################################################
variable "db_secret_name" {
  description = "The exact name of the secret in Secrets Manager"
  type        = string
}
#############################################################
variable "vpc_cidr_block" {
  description = "VPC cidr block"
  type = string
}


##############################################################
variable "env_prefix" {
  description = "project environment"
  type = string

}
#############################################################
variable "project" {
  description = "project name"
  type = string
}
###############################################################
variable "avail_zones" {
  description = "List of Availability Zones to use"
  type        = list(string)
}
#############################################################
variable "public_subnet_cidrs" {
  description = "List of Public Subnet CIDRs"
  type        = list(string)
}
#############################################################
variable "private_subnet_cidrs_app" {
  description = "List of Private APP Subnet CIDRs"
  type        = list(string)
}
############################################################

variable "private_subnet_cidrs_db" {
  description = "List of Private DB Subnet CIDRs"
  type        = list(string)
}

############################################################
variable "rtb_public_cidr" {
  description = "route table public cidr"
  type = string
}
############################################################
variable "instance_type" {
  type        = string
  description = "The type of EC2 instance to launch"
} 
############################################################

variable "sns_email" {
  description = "Email address for alarm notifications"
  type        = string
}
############################################################
# ---------------------------------------------------------
# BONUS B/C: INGRESS CONFIG
# ---------------------------------------------------------
variable "domain_name" {
  description = "The FQDN for the application (e.g., lab1c.couch2cloud.dev)"
  type        = string
}
############################################################