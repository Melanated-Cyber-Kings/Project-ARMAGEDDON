

terraform {
  backend "s3" {
    bucket         = "project-armageddon-tf-tokyo-theswordpt"
    key            = "lab3/tokyo.tfstate"
    region         = "ap-northeast-1"
    #dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}


data "terraform_remote_state" "saopaulo" {
  backend = "s3"
  config = {
    bucket = "project-armageddon-tf-saopaulo-theswordpt"
    key    = "lab3/saopaulo.tfstate"
    region = "sa-east-1"
  }
}