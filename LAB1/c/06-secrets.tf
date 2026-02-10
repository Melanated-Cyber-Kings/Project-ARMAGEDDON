# ############################################
# # Secrets Manager (DB Credentials)
# ############################################

# Explanation: Secrets Manager is Chewbacca’s locked holster—credentials go here, not in code.
resource "aws_secretsmanager_secret" "db_secret01" {
  name = var.secret_name
  recovery_window_in_days = 0
}

# Explanation: Secret payload—students should align this structure with their app (and support rotation later).
resource "aws_secretsmanager_secret_version" "db_secret_version01" {
  secret_id = aws_secretsmanager_secret.db_secret01.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password

  })
}

