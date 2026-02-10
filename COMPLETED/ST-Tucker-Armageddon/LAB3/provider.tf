# terraform {
#   required_providers {
#     random = {
#       source = "hashicorp/random"
#       version = "~> 3.0"
#     }
#     aws = {
#       source = "hashicorp/aws"
#       version = "~> 5.0"
#     }
#   }
# }

# Tokyo provider (default)
provider "aws" {
  region = "ap-northeast-1"
}

# Sao Paulo provider
provider "aws" {
  alias  = "saopaulo"
  region = "sa-east-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}