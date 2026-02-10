# backend.tf
terraform {
  backend "s3" {
    bucket         = "prjct-arm-tf-state"
    key            = "lab-2a/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}