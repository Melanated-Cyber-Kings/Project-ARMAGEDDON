###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: ec2
# PURPOSE: Launch private EC2 instance with user data and IAM role.
###############################################################################


# Amazon Machine Image (AMI) ID for Amazon Linux 2 in us-east-1 region.
# We use a data source to dynamically fetch the latest AMI ID for Amazon Linux 2023.
# This ensures that we always use the most up-to-date AMI when launching our EC2 instance.
# Also helps avoid hardcoding AMI IDs, which can become outdated over time.

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}


# ec2/main.tf
resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids

  # Private instance: no public IPv4
  associate_public_ip_address = false

  # Instance metadata: require IMDSv2 (recommended when metadata is used for bootstrap logic)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }


  user_data            = file("${path.module}/user_data.sh")
  iam_instance_profile = var.instance_profile_name

  # When user_data changes, replace the instance to apply the new configuration.
  # This is important because user_data is only executed during the initial 
  # launch of the instance. Had to add this to ensure that any changes to 
  # the user_data script would trigger a replacement of the EC2 instance, 
  # allowing the new user_data to be applied correctly.

  user_data_replace_on_change = true

  # Ensure that the new instance is created before the old one is destroyed
  # to minimize downtime during updates.
  # 
  
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-ec2-app"
  })
}
