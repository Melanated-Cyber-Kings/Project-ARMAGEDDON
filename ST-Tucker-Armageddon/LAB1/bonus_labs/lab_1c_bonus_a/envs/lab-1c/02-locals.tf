###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: environment (locals)
# PURPOSE: Local values for Lab 1C environment
###############################################################################

locals {
  # Naming
  name_prefix = lower("${var.project}-${var.env_prefix}")

  instance_type_by_env = {
    lab1a = "t3.micro"
    lab1b = "t3.micro"
    lab2  = "t3.micro"
  }

  # Default tags
  tags = {
    Environment = "${var.env_prefix}"
    ManagedBy   = "Terraform"
  }

  ###########################################################################
  # Secrets Manager: Decode the current secret value into an object
  ###########################################################################
  rds_secret = jsondecode(
    data.aws_secretsmanager_secret_version.rds.secret_string
  )

  ###########################################################################
  # Canonical DB fields (handles db_name vs dbname inconsistencies)
  #
  # If the secret contains:
  #   - db_name  -> use it
  #   - dbname   -> use it
  # Otherwise fall back to var.db_name (from tfvars)
  ###########################################################################
  rds_db_name = coalesce(
    try(local.rds_secret.db_name, null),
    try(local.rds_secret.dbname, null),
    var.db_name
  )

  # Canonical credential fields (use secret when present)
  rds_username = coalesce(try(local.rds_secret.username, null), var.db_username)
  rds_password = coalesce(try(local.rds_secret.password, null), var.db_password)

  # Canonical connection fields (host/port are expected in secret)
  rds_host = try(local.rds_secret.host, null)
  rds_port = coalesce(try(local.rds_secret.port, null), 3306)
}
