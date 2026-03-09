# Sao Paulo provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}

provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1" 
}
