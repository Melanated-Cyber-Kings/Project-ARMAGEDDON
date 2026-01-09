output "vpc_id" {
  value = aws_vpc.this.id   # assuming your VPC resource inside module is called "this"
}

