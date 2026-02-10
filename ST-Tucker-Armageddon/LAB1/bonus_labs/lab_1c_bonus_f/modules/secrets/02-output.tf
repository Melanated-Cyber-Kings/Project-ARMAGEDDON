###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: secrets (module)
# PURPOSE: Outputs for the Terraform-owned Secrets Manager secret.
###############################################################################

output "secret_name" {
  description = "Name of the RDS credentials secret."
  value       = aws_secretsmanager_secret.rds_secret.name
}

output "secret_arn" {
  description = "ARN of the RDS credentials secret."
  value       = aws_secretsmanager_secret.rds_secret.arn
}

output "secret_id" {
  description = "Secrets Manager secret id for grader gates."
  value       = aws_secretsmanager_secret.rds_secret.id
}
