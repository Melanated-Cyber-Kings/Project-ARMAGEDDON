###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: environment
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

# ============================================================
# Project: Armageddon — AWS Terraform Labs
# Lab:     1B
# Scope:   LAB1/b/envs/lab-1b
# File:    05-backend.tf
# Purpose: Backend declaration only. Backend values are provided via backend.hcl.
# ============================================================

terraform {
  backend "s3" {}
}
