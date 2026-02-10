# providers.tf - FIXED VERSION
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "prjct-arm-tf-state"
    key    = "lab3a/saopaulo/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

# DEFAULT provider (no alias)
provider "aws" {
  region = var.aws_region
  # No alias - this is the default
}

# ALIASED provider for São Paulo resources
provider "aws" {
  alias  = "sao_paulo"
  region = "sa-east-1"  # Explicitly set region, don't use var
}

# If you need Tokyo provider for cross-region
provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1"
}
