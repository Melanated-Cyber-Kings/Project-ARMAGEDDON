# Description: Global Secrets Catalog Backend
# Source Reference: [LAB2 | secrets/02-backend.tf]

terraform {
  backend "s3" {
    bucket         = "armageddon-tf-state-tokyo" # Store it in your primary hub bucket
    key            = "global/secrets.tfstate"     # Use a 'global' path
    region         = "ap-northeast-1"
    # Note: Skipping DynamoDB lock as per your solo-build decision
    encrypt        = true
  }
}