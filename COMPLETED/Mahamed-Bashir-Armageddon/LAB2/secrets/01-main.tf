terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region = var.region
}

resource "aws_secretsmanager_secret" "rds_secrets" {
  # This creates one secret per item in the active_missions list
  for_each = toset(var.active_missions)
  
  name = "${each.value}/rds/mysql"
  
  tags = {
    Mission = each.value
    ManagedBy = "Terraform-Secrets-Catalog"
  }
}