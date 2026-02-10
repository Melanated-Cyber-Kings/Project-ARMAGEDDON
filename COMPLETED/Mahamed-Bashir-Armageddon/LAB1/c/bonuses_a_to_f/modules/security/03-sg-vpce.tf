resource "aws_security_group" "vpce_sg" {
  name        = "vpce-${var.name_prefix}"
  description = "Allow HTTPS from EC2 to VPC Endpoints"
  vpc_id      = var.vpc_id
  tags = { Name = "sg-vpce-${var.name_prefix}" }
}
resource "aws_vpc_security_group_ingress_rule" "vpce_https_from_ec2" {
  security_group_id            = aws_security_group.vpce_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}