# Default Region
provider "aws" {
  region = var.region 
  
}

# The Global Region (us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}