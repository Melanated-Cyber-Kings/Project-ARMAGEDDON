###############################################################################
# modules/security/07-sg-alb.tf
# ALB Security Group + ingress rules (centralized in security module)
###############################################################################

# CloudFront origin-facing prefix list (AWS-managed, global name)
data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing" {
  count = var.alb_ingress_mode == "cloudfront_prefix_list" ? 1 : 0
  name  = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.env_prefix}-alb-sg"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name   = "${var.env_prefix}-alb-sg"
    Module = "security"
  })
}

###############################################################################
# Ingress: HTTPS 443
###############################################################################

# Mode: public_443 (optional)
resource "aws_security_group_rule" "alb_ingress_https_public" {
  count             = var.alb_ingress_mode == "public_443" ? 1 : 0
  type              = "ingress"
  description       = "HTTPS from internet"
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Mode: cloudfront_prefix_list (LAB-2A intent)
resource "aws_security_group_rule" "alb_ingress_https_cloudfront" {
  count             = var.alb_ingress_mode == "cloudfront_prefix_list" ? 1 : 0
  type              = "ingress"
  description       = "HTTPS from CloudFront origin-facing prefix list"
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"

  prefix_list_ids = [
    data.aws_ec2_managed_prefix_list.cloudfront_origin_facing[0].id
  ]
}

###############################################################################
# Optional: Ingress HTTP 80
###############################################################################
resource "aws_security_group_rule" "alb_ingress_http_public" {
  count             = var.alb_allow_http_80 ? 1 : 0
  type              = "ingress"
  description       = "HTTP from internet (optional; usually redirect to HTTPS)"
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

###############################################################################
# Egress: allow all
###############################################################################
resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  description       = "Allow all outbound"
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
