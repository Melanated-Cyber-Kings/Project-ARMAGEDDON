###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: iam
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

output "role_name" {
  value = aws_iam_role.ec2_secrets_role.name
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2_profile.name
}
