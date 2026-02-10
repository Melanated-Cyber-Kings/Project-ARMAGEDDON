resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-${var.env_prefix}"
  description = "Allow inbound traffic to Armageddon vpc"
  vpc_id      = var.vpc_id

  tags = {
    Name = "alb-sg-${var.env_prefix}"
  }
}

# Explanation: shinjuku only opens the hangar to CloudFront — everyone else gets the Wookiee roar.
data "aws_ec2_managed_prefix_list" "shinjuku_cf_origin_facing01" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_vpc_security_group_ingress_rule" "cloudfront_ingress" {
  description       = "CloudFront HTTP/HTTPS ingress (80-443)"
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 443  # Single rule covering both HTTP and HTTPS
  prefix_list_id    = data.aws_ec2_managed_prefix_list.shinjuku_cf_origin_facing01.id

  tags = {
    Name        = "CloudFront ingress"
    PortRange   = "80-443"
    Component   = "alb"
    ManagedBy   = "terraform"
  }
}

# resource "aws_vpc_security_group_ingress_rule" "alb-http" {
#   description = "HTTP from Cloudfront origin-facing IPs"
#   security_group_id = aws_security_group.alb_sg.id

#   #cidr_ipv4         = "0.0.0.0/0"
#   #LAB2 cloudfront prefix_list_id
#   prefix_list_id = data.aws_ec2_managed_prefix_list.shinjuku_cf_origin_facing01.id

#   from_port         = 80
#   ip_protocol       = "tcp"
#   to_port           = 80

# ## tags to name the security group rule
#    tags = {
#      Name = "HTTP from Cloudfront "
#    }
# }

# resource "aws_vpc_security_group_ingress_rule" "alb-https" {
#   security_group_id = aws_security_group.alb_sg.id
#   ip_protocol       = "tcp"
#   from_port         = 443
#   to_port           = 443

#   #cidr_ipv4         = "0.0.0.0/0"
#   #LAB2 cloudfront prefix_list_id
#   prefix_list_id = data.aws_ec2_managed_prefix_list.shinjuku_cf_origin_facing01.id

#   description       = "Allow HTTPS from Cloudfront origin-facing IPs"

#   ## tags to name the security group rule
#    tags = {
#      Name = "HTTPS from Cloudfront"
#    }
# }

resource "aws_vpc_security_group_egress_rule" "alb-outbound" {
  description = "Allow ALB to forward to EC2 on port 80"
  security_group_id = aws_security_group.alb_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id
  ip_protocol = "tcp"
  from_port = 80
  to_port = 80

  tags = {
     Name = "ALB to EC2"
   }
}