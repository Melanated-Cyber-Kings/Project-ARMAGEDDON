###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: security
# PURPOSE: Security group for VPC Interface Endpoints (VPCE)
###############################################################################

resource "aws_security_group" "vpce_endpoints_sg" {
  name        = "vpce-interface-endpoints-${var.env_prefix}"
  description = "Allow HTTPS from EC2 SG to VPC interface endpoints"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "vpce-interface-endpoints-${var.env_prefix}"
  })
}

resource "aws_vpc_security_group_ingress_rule" "vpce_https_from_ec2" {
  description                  = "HTTPS from EC2 SG"
  security_group_id            = aws_security_group.vpce_endpoints_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "vpce_all_outbound" {
  description       = "All egress"
  security_group_id = aws_security_group.vpce_endpoints_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
