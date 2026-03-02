# ec2/main.tf
#this will have to change if we no longer use t3.micro
data "aws_ami" "latest_t3_micro" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]  # example for Amazon Linux 2 AMI
  }

  owners = ["amazon"]  # owner alias for official Amazon images
}


resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.latest_t3_micro.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  
  #lab1c, no more public ip
  #associate_public_ip_address = true

  user_data = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true  # Triggers destroy/recreate on changes

  iam_instance_profile = var.instance_profile_name

  tags = {
    Name = "${var.env_prefix}-ec2-app"
  }
}
