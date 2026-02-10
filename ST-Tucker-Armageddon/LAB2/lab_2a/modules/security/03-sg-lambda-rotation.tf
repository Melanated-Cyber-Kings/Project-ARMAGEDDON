###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: security
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

# ============================================================
# Lab 1C — Security: Lambda Rotation SG
# 
# ============================================================

resource "aws_security_group" "lambda_rotation_sg" {
  name        = "lambda-rotation-lab-2a"
  description = "Security group for Secrets Manager rotation Lambda"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-lambda-rotation-sg"
  })
}

# EGRESS: DB port -> RDS SG (least privilege)
resource "aws_vpc_security_group_egress_rule" "lambda_to_rds" {
  security_group_id            = aws_security_group.lambda_rotation_sg.id
  referenced_security_group_id = aws_security_group.rds_sg.id

  from_port   = var.tcp_ingress_rule.port
  to_port     = var.tcp_ingress_rule.port
  ip_protocol = "tcp"

  description = "Allow rotation Lambda to reach RDS on DB port"
}

# EGRESS: HTTPS -> AWS APIs (Secrets Manager, CloudWatch Logs, etc.) via NAT
resource "aws_vpc_security_group_egress_rule" "lambda_https_outbound" {
  security_group_id = aws_security_group.lambda_rotation_sg.id
  cidr_ipv4         = "0.0.0.0/0"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "Allow rotation Lambda to call AWS APIs over HTTPS"
}
