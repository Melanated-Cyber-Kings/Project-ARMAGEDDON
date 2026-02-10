provider "aws" {
  region = var.aws_region
}

# This stays OUTSIDE the braces of the provider block
data "aws_caller_identity" "chewbacca_self01" {}