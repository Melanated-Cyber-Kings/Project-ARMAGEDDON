# ------------------------------------------------------------------
# 1. DYNAMIC AMI LOOKUP
# ------------------------------------------------------------------
data "aws_ssm_parameter" "latest_al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ------------------------------------------------------------------
# 2. THE LAUNCH TEMPLATE
# ------------------------------------------------------------------
resource "aws_launch_template" "armageddon_lt" {
  name = "${var.name_prefix}-lt"
  
  image_id      = data.aws_ssm_parameter.latest_al2023.value
  instance_type = var.instance_type
  
  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    security_groups = var.security_group_ids
  }
  
  user_data = base64encode(var.user_data)
}

# --- THE AUTO SCALING GROUP ---
resource "aws_autoscaling_group" "app_asg" {
  name                = "${var.name_prefix}-asg"
  vpc_zone_identifier = var.private_app_subnet_ids
  target_group_arns   = [var.target_group_arn_for_asg]
  health_check_type   = "ELB"
  
  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.armageddon_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-app-node"
    propagate_at_launch = true
  }
}