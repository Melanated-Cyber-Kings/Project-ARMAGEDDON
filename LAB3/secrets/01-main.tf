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
  
  for_each = toset(var.active_missions)
  
  name = "${each.value}/rds/mysql"

  replica {
    region = "sa-east-1"
  }

  tags = {
    Mission = each.value
    ManagedBy = "Terraform-Secrets-Catalog"
  }
}