output "ssm_parameter_names" {
  description = "SSM parameter names"
  value = {
    endpoint = aws_ssm_parameter.db_endpoint.name
    port     = aws_ssm_parameter.db_port.name
    name     = aws_ssm_parameter.db_name.name
  }
}

# output "secret_arn" {
#   description = "Secrets Manager secret ARN"
#   value       = aws_secretsmanager_secret.db_credentials.arn
# }

output "secret_arn" {
  value       = data.aws_secretsmanager_secret.db_credentials.arn
  description = "ARN of the DB credentials secret"
}

output "secret_id" {
  value = data.aws_secretsmanager_secret.db_credentials.id
  description = "ID of DB credentials secret"
}