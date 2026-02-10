###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: iam
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

output "role_name" {
  value = aws_iam_role.ec2_secrets_role.name
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_role_name" {
  description = "Name of the EC2 IAM role attached to the instance profile"
  value       = aws_iam_role.ec2_secrets_role.name
}
