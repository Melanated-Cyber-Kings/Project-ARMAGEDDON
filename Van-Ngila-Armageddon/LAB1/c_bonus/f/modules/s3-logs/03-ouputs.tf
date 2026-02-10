# output "alb_logs_bucket_name" {
#   value = var.enable_alb_access_logs ? aws_s3_bucket.alb_logs_bucket[0].bucket : null
# }

# output "alb_logs_bucket_arn" {
#   value = var.enable_alb_access_logs ? aws_s3_bucket.alb_logs_bucket[0].arn : null
# }

# output "alb_logs_bucket_id" {
#   value = var.enable_alb_access_logs ? aws_s3_bucket.alb_logs_bucket[0].id : null
# }

# CORRECTED OUTPUTS:
output "alb_logs_bucket_name" {
  description = "Name of the ALB logs S3 bucket"
  value       = var.enable_alb_access_logs && length(aws_s3_bucket.alb_logs_bucket) > 0 ? aws_s3_bucket.alb_logs_bucket[0].bucket : ""
}

output "alb_logs_bucket_arn" {
  description = "ARN of the ALB logs S3 bucket"
  value       = var.enable_alb_access_logs && length(aws_s3_bucket.alb_logs_bucket) > 0 ? aws_s3_bucket.alb_logs_bucket[0].arn : ""
}

output "alb_logs_bucket_id" {
  description = "ID of the ALB logs S3 bucket"
  value       = var.enable_alb_access_logs && length(aws_s3_bucket.alb_logs_bucket) > 0 ? aws_s3_bucket.alb_logs_bucket[0].id : ""
}

output "alb_logs_bucket_dependency" {
  description = "Dependency reference for the ALB logs bucket"
  value       = var.enable_alb_access_logs && length(aws_s3_bucket_policy.alb_logs_policy) > 0 ? aws_s3_bucket_policy.alb_logs_policy[0].id : null
}