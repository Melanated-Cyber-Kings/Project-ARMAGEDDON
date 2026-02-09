###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: environment
# FILE: 02-locals.tf
# PURPOSE: Locals for naming and tags (no dependency on Secrets Manager data).
###############################################################################

locals {
  # Canonical naming prefix used across modules
  name_prefix = var.env_prefix

  # Consistent tag set used throughout the environment
  tags = merge(
    var.tags,
    {
      Environment = var.env_prefix
      Project     = var.project
    }
  )
}
