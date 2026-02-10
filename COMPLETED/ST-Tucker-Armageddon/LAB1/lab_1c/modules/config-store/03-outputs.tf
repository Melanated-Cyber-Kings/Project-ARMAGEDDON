###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: general
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

output "ssm_parameter_names" {
  description = "SSM parameter names"
  value = {
    endpoint = aws_ssm_parameter.db_endpoint.name
    port     = aws_ssm_parameter.db_port.name
    name     = aws_ssm_parameter.db_name.name
  }
}

output "secret_arn" {
  description = "Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.db_credentials.arn
}