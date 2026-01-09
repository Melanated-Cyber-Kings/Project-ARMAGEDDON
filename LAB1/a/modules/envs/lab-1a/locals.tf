locals {
  name_prefix = "${var.project}-${var.env_prefix}"   # note the space after the dash

  instance_type_by_env = {
    lab1a = "t3.micro"
    lab1b = "t3.micro"
    lab2  = "t3.micro"
  }

  tags = {
    Environment = var.env_prefix
    ManagedBy   = "Terraform"
  }
}