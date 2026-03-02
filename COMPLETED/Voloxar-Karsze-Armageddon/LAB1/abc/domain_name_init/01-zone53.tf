resource "aws_route53_zone" "primary" {
  name = var.domain_name

  comment       = "Public hosted zone for ${var.domain_name}"
  force_destroy = false


tags = {
    Name = "${var.env_prefix}-domain-name"
  }

}

provider "aws" {
  region = var.region
}