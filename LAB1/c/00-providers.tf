provider "aws" {
  region = var.aws_region
}

# versions.tf here insteasd of versions.tf file
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}