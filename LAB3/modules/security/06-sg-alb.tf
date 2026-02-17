data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "alb_sg" {
  name_prefix = "alb-${var.name_prefix}-"
  description = "ALB Ingress - Locked to CloudFront"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "sg-alb-${var.name_prefix}" }
}

# ONLY Port 443 is needed. Port 80 is removed to save Quota.
resource "aws_vpc_security_group_ingress_rule" "alb_https_cf" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow CloudFront Origin-Facing IPs only"
  
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_all_outbound" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}