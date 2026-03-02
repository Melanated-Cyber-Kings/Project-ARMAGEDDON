terraform {
  backend "s3" {
    bucket         = "armageddon-tf-saopaulo-theswordpt"
    key            = "lab3/saopaulo.tfstate"
    region         = "sa-east-1"
    #dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}


data "terraform_remote_state" "tokyo" {
  backend = "s3"
  config = {
    bucket = "armageddon-tf-tokyo-theswordpt"
    key    = "lab3/tokyo.tfstate"
    region = "ap-northeast-1"
  }
}