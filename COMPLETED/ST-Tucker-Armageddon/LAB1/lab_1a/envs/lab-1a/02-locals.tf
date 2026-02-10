###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: environment
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

# -------------------------------------------------
# LAB 1A — Local Values
# -------------------------------------------------

locals {

  # Canonical name prefix used across all modules
  name_prefix    = "${var.project}-${var.env_prefix}"
  name_prefix_lc = lower(local.name_prefix)

  # Standard tags applied to every resource
  tags = {
    Project     = var.project
    Environment = var.env_prefix
    ManagedBy   = "Terraform"
    Lab         = "LAB1A"
  }
}
