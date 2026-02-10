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

# output "ec2_instance_id" {
#   value = aws_instance.ec201.id
# }

output "rds_endpoint" {
  value = aws_db_instance.rds01.address
}

# output "sns_topic_arn" {
#   value = aws_sns_topic.sns_topic01.arn
# }

# output "log_group_name" {
#   value = aws_cloudwatch_log_group.log_group01.name
# }


# output "s3_bucket_name" {
#   value = aws_s3_bucket.app_dependencies.bucket
# } 



output "lab1_waf_log_destination" {
  description = "The chosen destination type for WAF logging"
  value       = var.waf_log_destination
}

output "lab1_waf_cw_log_group_name" {
  description = "The name of the CloudWatch Log Group for WAF"
  value       = var.waf_log_destination == "cloudwatch" ? aws_cloudwatch_log_group.lab1_waf_log_group01[0].name : null
}

# output "lab1_waf_logs_s3_bucket" {
#   description = "The name of the S3 bucket where WAF logs are stored"
#   value       = var.waf_log_destination == "s3" ? aws_s3_bucket.lab1_waf_logs_bucket01[0].bucket : null
# }

# output "lab1_waf_firehose_name" {
#   description = "The name of the Kinesis Firehose stream for WAF logs"
#   value       = var.waf_log_destination == "firehose" ? aws_kinesis_firehose_delivery_stream.lab1_waf_firehose01[0].name : null
# }


