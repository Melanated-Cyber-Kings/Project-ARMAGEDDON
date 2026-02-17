# Default Region Provider
provider "aws" {
  region = var.region 
  
}

#Global Region (us-east-1) for CloudFront and ACM
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}