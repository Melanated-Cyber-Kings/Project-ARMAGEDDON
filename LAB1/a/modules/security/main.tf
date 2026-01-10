# ==========================================
# 1. EC2 SECURITY GROUP 
# ==========================================
resource "aws_security_group" "ec2" {
  name        = "${var.env_prefix}-ec2-sg"
  description = "Allow Web and SSH Traffic"
  vpc_id      = var.vpc_id

  # --- DYNAMIC BLOCK---
  # Loops through list to create ingress rules
  dynamic "ingress" {
    for_each = var.ec2_ingress_rules
    
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  

# Outbound: Allow All
  egress {
    description = "Allow all outbound traffic"
    from_port   = var.any_port      
    to_port     = var.any_port      
    protocol    = var.any_protocol  
    cidr_blocks = var.all_ips      
  }

  tags = {
    Name = "${var.env_prefix}-ec2-sg"
  }
}

# ==========================================
# 2. RDS SECURITY GROUP
# ==========================================
resource "aws_security_group" "rds" {
  name        = "${var.env_prefix}-rds-sg"
  description = "Allow DB traffic from App Layer"
  vpc_id      = var.vpc_id

  # Inbound: Allow MySQL from EC2 SG
    ingress {
    description     = "Access Database from EC2"
    from_port       = var.db_port       
    to_port         = var.db_port       
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }


  # Outbound: Allow All
  egress {
    description = "Allow all outbound traffic"
    from_port   = var.any_port      
    to_port     = var.any_port      
    protocol    = var.any_protocol  
    cidr_blocks = var.all_ips       
  }

  tags = {
    Name = "${var.env_prefix}-rds-sg"
  }
}