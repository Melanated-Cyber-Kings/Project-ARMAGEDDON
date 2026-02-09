# ============================================================
# Project: Armageddon — AWS Terraform Labs
# Lab:     1B
# Scope:   LAB1/b/bootstrap
# File:    terraform.tfvars.example
# Purpose: Example values for provisioning Terraform remote-state infrastructure.
# ============================================================

##############################################
# AWS Region
##############################################

region = "ap-northeast-1"

##############################################
# Terraform State S3 Bucket
# (Must be globally unique)
##############################################

tf_state_bucket_name = "arma-lab1b-bucket-tfstate"

##############################################
# DynamoDB Lock Table
##############################################

tf_lock_table_name = "terraform-state-locks"

##############################################
# Tags applied to backend resources
##############################################

tags = {
  Project        = "Armageddon"
  Lab            = "1B"
  Environment    = "training"
  Owner          = "user"
  CostCenter     = "education"
  ManagedBy      = "terraform"
  Repository     = "armageddon-lab1b"
  Classification = "public"
}
