# provider "aws" {
#   region = var.region
# }

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"  # Allows latest 6.x releases
    }
  }
}

provider "aws" {
  alias  = "sao_paulo"
  region = "sa-east-1"
}