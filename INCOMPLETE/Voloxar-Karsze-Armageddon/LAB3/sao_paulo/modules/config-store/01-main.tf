# Fetch the current value of the parameter
# data "aws_ssm_parameter" "db_endpoint" {
#   name = "/lab/db/endpoint"
#   # If the parameter doesn't exist yet, this will cause the resource to be created
#   # so it's safe even if the parameter does not exist.
#   # from chatgpt, trying to avoid TooManyUpdates error
# }

#This didn't work: Create or update the parameter only if its value has changed
resource "aws_ssm_parameter" "db_endpoint" {
  name        = "/lab/db/endpoint"
  type        = "String"
  value       = var.db_endpoint
  description = "RDS endpoint for lab application"
  #overwrite   = var.db_endpoint != data.aws_ssm_parameter.db_endpoint.value

  overwrite = true

  lifecycle {
    ignore_changes = [value]
  }
  tags = var.tags
}

resource "aws_ssm_parameter" "db_port" {
  name        = "/lab/db/port"
  type        = "String"
  value       = var.db_port
  description = "RDS port for lab application"
  tags        = var.tags
 
 
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/lab/db/name"
  type        = "String"
  value       = var.db_name
  description = "RDS database name for lab application"
  tags        = var.tags
 
 
}

# Secrets Manager for DB credentials
#resource "aws_secretsmanager_secret" "db_credentials" {
data "aws_secretsmanager_secret" "db_credentials" {
  name        = "lab/rds/mysql"
  #description = "Database credentials for lab RDS instance"

  # recovery_window_in_days = 0
  # force_overwrite_replica_secret = true
  
  # tags = merge(var.tags, {
  #   Rotation = "manual"
  # })
}

# resource "aws_secretsmanager_secret_version" "db_credentials_version" {
#   secret_id = aws_secretsmanager_secret.db_credentials.id
#   secret_string = jsonencode({
#     username = var.db_username
#     password = var.db_password
#     host     = var.db_endpoint
#     port     = var.db_port
#     dbname   = var.db_name
#   })
# }


resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_endpoint
    port     = var.db_port
    db_name  = var.db_name
    engine   = "mysql"
  })
}

#from chatgpt
# Ensure Long Delays Between Parameter Updates

# Even with the lifecycle settings, it might 
# still be hitting AWS rate limits on parameter 
# updates if multiple updates are being requested 
# in quick succession. You can try introducing 
# a more significant manual delay between updates 
# using Terraform's time_sleep resource.

#worthless
# resource "time_sleep" "wait_60_seconds" {
#   depends_on = [aws_ssm_parameter.db_endpoint]
#   create_duration = "60s"
# }