############################################
# Security Group: ALB
############################################

# Explanation: The ALB SG is the blast shield — only allow what the Rebellion needs (80/443).
resource "aws_security_group" "alb_sg01" {
  name        = "${var.project}-alb-sg01"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  # TODO: students add inbound 80/443 from 0.0.0.0/0
  # Done
  # Inbound: 80 and 443 from anywhere
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    # TODO: students set outbound to target group port (usually 80) to private targets
    # Done
    egress {
    description     = "Only to target ec2 group on port 80"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  tags = {
    Name = "${var.project}-alb-sg01"
  }
}


# resource "aws_security_group_rule" "ec2_ingress_from_alb01" {
#   type                     = "ingress"
#   security_group_id        = aws_security_group.ec2_sg.id
#   from_port                = 80
#   to_port                  = 80
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.alb_sg01.id
#   description              = "Allow HTTP from ALB"  # Optional but recommended
# }  #   egress {
  #   description     = "Only to target ec2 group on port 80"
  #   from_port       = 80
  #   to_port         = 80
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.ec2_sg.id]
  # }  #   egress {
  #   description     = "Only to target ec2 group on port 80"
  #   from_port       = 80
  #   to_port         = 80
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.ec2_sg.id]
  # }