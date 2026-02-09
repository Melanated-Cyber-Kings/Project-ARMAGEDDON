###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: envs
# PURPOSE: Local values shared across modules.
###############################################################################

locals {

  ###########################################################################
  # Name prefix
  ###########################################################################
  name_prefix = var.env_prefix

  ###########################################################################
  # Standard tags used across modules
  ###########################################################################
  tags = var.tags

  ###########################################################################
  # Pull DB secret from Secrets Manager
  ###########################################################################
  rds_secret = jsondecode(
    data.aws_secretsmanager_secret_version.rds.secret_string
  )

  ###########################################################################
  # Normalize DB name key across labs:
  # - secrets JSON uses "dbname"
  # - Terraform modules expect "db_name"
  ###########################################################################
  normalized_db_name = try(
    local.rds_secret.db_name,
    local.rds_secret.dbname,
    var.db_name
  )

}
