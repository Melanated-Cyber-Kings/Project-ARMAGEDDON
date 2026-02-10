###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: ec2
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

# -----------------------------
# Naming / Tagging
# -----------------------------

variable "env_prefix" {
  type        = string
  description = "Prefix for EC2 resource names."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to EC2 resources."
}

# -----------------------------
# Networking
# -----------------------------

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the EC2 instance will be launched."
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups attached to the EC2 instance."
}

# -----------------------------
# IAM
# -----------------------------

variable "instance_profile_name" {
  type        = string
  description = "IAM instance profile name attached to the EC2 instance."
}

# -----------------------------
# Instance Configuration
# -----------------------------

variable "instance_type" {
  type        = string
  description = "EC2 instance type."
}

# -----------------------------
# Secure Shell Key Pair
# -----------------------------
variable "key_name" {
  description = "EC2 Key Pair name for SSH access (optional)"
  type        = string
  default     = null
}
