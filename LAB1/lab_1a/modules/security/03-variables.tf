###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: security
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

# -----------------------------
# Core Inputs
# -----------------------------

variable "vpc_id" {
  type        = string
  description = "VPC ID for security groups."
}

variable "env_prefix" {
  type        = string
  description = "Prefix used when naming security groups."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to security groups."
  default     = {}
}

# -----------------------------
# EC2 Ingress Controls (Lab Defaults)
# -----------------------------

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to SSH into the EC2 instance."
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to access HTTP on the EC2 instance."
  default     = ["0.0.0.0/0"]
}

# -----------------------------
# RDS / DB Controls
# -----------------------------

variable "db_port" {
  type        = number
  description = "Database port allowed from EC2 to RDS."
  default     = 3306
}
