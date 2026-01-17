# ec2/main.tf
resource "aws_instance" "ec2" {
  ami                    = "ami-03d1820163e6b9f5d"
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  associate_public_ip_address = true

  tags = {
    Name = "${var.env_prefix}-ec2-app"
  }
}