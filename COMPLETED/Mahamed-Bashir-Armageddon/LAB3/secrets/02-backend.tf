#Global Secrets Catalog Backend

terraform {
  backend "s3" {
    bucket         = "armageddon-tf-state-tokyo" 
    key            = "global/secrets.tfstate"     
    region         = "ap-northeast-1"
    encrypt        = true
  }
}