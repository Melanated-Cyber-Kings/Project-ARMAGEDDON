output "asg_name" {
  value = aws_autoscaling_group.app_asg.name
}

output "launch_template_id" {
  value = aws_launch_template.armageddon_lt.id
}

output "ec2_id" {
  value = "asg-managed"
}