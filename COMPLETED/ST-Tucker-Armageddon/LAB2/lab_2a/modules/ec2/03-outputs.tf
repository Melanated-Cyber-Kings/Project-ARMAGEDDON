###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: ec2
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

output "ec2_id" {
  value = aws_instance.ec2.id
}

output "ec2_private_ip" {
  value = aws_instance.ec2.private_ip
}

output "ec2_public_ip" {
  value = aws_instance.ec2.public_ip
}
