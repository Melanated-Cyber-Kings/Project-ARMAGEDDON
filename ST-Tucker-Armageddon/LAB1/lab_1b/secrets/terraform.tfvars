# ============================================================
# Project: Armageddon — AWS Terraform Labs
# Lab:     1B
# Stack:   secrets
# File:    terraform.tfvars.example
#
# Purpose:
#   Input values for provisioning database credentials and
#   baseline configuration in AWS Secrets Manager and
#   SSM Parameter Store.
#
# Usage:
#   cp terraform.tfvars.example terraform.tfvars
#   Edit terraform.tfvars with real values
#
# Notes:
#   - Set the database port based on the engine used in envs:
#       * PostgreSQL → 5432
#       * MySQL / MariaDB → 3306
# ============================================================

##############################################
# AWS Region
##############################################

region = "ap-northeast-1"

##############################################
# Naming Prefix (used for Secrets + SSM paths)
##############################################

env_prefix = "lab-1b"

##############################################
# Database Credential Material
# (stored securely in Secrets Manager)
##############################################

username = "admin"
password = "StrongPassword123!"
dbname   = "labdb"
address  = "lab-mysql.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com"


# Database port:
# PostgreSQL = 5432
# MySQL/MariaDB = 3306
port = 3306


##############################################
# Rotation OPTIONAL (default OFF)
#
# Enable rotation by setting either:
#   rotation_lambda_account_id = "<ACCOUNT_ID>"
#   rotation_lambda_name       = "<FUNCTION_NAME>"
#
# To get your account id:
#   aws sts get-caller-identity --query Account --output text
##############################################

#rotation_lambda_account_id = null
#rotation_lambda_name       = null

rotation_lambda_arn = "arn:aws:lambda:ap-northeast-1:261519058382:function:lab-1b-rds-rotation-mysql"
rotation_days       = 30

##############################################
# Secret value management
#
# If importing an existing secret and you want Terraform to
# preserve the current SecretString, set manage_secret_value=false.
##############################################

manage_secret_value = true


##############################################
# Optional resource tags
##############################################

# tags = {
#   Project = "Armageddon"
#   Lab     = "1B"
# }
