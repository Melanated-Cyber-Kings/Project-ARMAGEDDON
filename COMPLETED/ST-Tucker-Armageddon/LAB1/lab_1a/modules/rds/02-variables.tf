###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: rds
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

variable "env_prefix" {
  type        = string
  description = "Prefix used for naming RDS resources."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to RDS resources."
}

# -----------------------------
# Networking / Placement
# -----------------------------

variable "db_subnet_group_name" {
  type        = string
  description = "Subnet group name for the RDS instance."
}

variable "rds_security_group_id" {
  type        = string
  description = "Security group ID attached to the RDS instance."
}

# -----------------------------
# Database Settings
# -----------------------------

variable "db_name" {
  type        = string
  description = "Initial database name."
}

variable "db_username" {
  type        = string
  description = "Master username for the database."
  sensitive   = true
}

variable "db_password" {
  type        = string
  description = "Master password for the database."
  sensitive   = true
}

# -----------------------------
# Engine / Instance Settings
# -----------------------------

variable "engine_version" {
  type        = string
  description = "MySQL engine version."
  default     = "8.0.43"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class."
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage in GB."
  default     = 20
}
