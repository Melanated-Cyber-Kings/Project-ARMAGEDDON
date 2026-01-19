output "sns_topic_arn" {
  value = aws_sns_topic.alarms.arn
}

output "lambda_function_arn" {
  value = aws_lambda_function.incident_response.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.incident_response.function_name
}