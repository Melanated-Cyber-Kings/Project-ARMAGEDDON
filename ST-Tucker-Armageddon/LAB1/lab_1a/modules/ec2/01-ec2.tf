###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: ec2
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

data "aws_ami" "selected" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "this" {

  ami           = data.aws_ami.selected.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile = var.instance_profile_name

  associate_public_ip_address = true

  key_name = var.key_name

  user_data = file("${path.module}/user_data.sh")

  root_block_device {
    encrypted   = true
    volume_size = 20
    volume_type = "gp3"
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.env_prefix}-ec2"
    }
  )
}
