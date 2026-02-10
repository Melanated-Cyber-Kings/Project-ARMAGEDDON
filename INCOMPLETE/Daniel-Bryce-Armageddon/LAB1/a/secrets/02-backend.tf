
/*
terraform {
  backend "s3" {
    bucket         = "project-armageddon-tf-state"
    key            = "lab-1a/secrets.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
*/