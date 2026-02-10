terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    # Configure your S3 backend here
      bucket = "prjct-arm-tf-state"
      key    = "lab3a/tokyo/terraform.tfstate"
      region = "ap-northeast-1"
  }
}

provider "aws" {
  region = "ap-northeast-1"
  alias  = "tokyo"
}
