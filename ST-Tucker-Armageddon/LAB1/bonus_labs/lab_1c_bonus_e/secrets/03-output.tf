###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: secrets
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

# output "address" {
#     value = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string)[address]
# }

output "secret_name" {
  description = "Name of the RDS credentials secret."
  value       = aws_secretsmanager_secret.rds_secret.name
}

output "secret_arn" {
  description = "ARN of the RDS credentials secret."
  value       = aws_secretsmanager_secret.rds_secret.arn
}

output "secretsmanager_secret_id" {
  description = "Secrets Manager secret id for grader gates"
  value       = aws_secretsmanager_secret.rds_secret.id
}
