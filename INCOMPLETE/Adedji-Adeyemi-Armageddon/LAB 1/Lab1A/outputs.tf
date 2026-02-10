# Explanation: Outputs are your mission report—what got built and where to find it.
output "vpc_id" {
  value = aws_vpc.lab1_vpc01.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}

output "ec2_instance_id" {
  value = aws_instance.ec201.id
}

# output "rds_endpoint" {
#   value = aws_db_instance.rds01.address
# }

# output "sns_topic_arn" {
#   value = aws_sns_topic.sns_topic01.arn
# }

# output "log_group_name" {
#   value = aws_cloudwatch_log_group.log_group01.name
# }

