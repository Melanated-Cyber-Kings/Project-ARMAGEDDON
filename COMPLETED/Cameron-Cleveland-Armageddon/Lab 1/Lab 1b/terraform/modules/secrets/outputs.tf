output "secrets_kms_key_arn" {
  value = aws_kms_key.secrets.arn
}

output "rds_secret_arn" {
  value = aws_secretsmanager_secret.rds_mysql.arn
}

output "ssm_parameters" {
  value = {
    endpoint = aws_ssm_parameter.db_endpoint.arn
    port     = aws_ssm_parameter.db_port.arn
    name     = aws_ssm_parameter.db_name.arn
  }
}

output "secrets_access_policy_arn" {
  value = aws_iam_policy.secrets_access.arn
}