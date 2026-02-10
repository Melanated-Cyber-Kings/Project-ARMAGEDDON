# This allows São Paulo to "peek" at Tokyo's homework
data "terraform_remote_state" "tokyo" {
  backend = "local"
  config = {
    path = "../tokyo/terraform.tfstate"
  }
}
