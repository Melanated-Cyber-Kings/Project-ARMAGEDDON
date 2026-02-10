# In modules/app_server/main.tf, add at the top:
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# Based on the syslog/main.tf pattern
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group
resource "aws_security_group" "app_server" {
  name        = "${var.name_prefix}-app-sg-v2"
  description = "Security group for application server"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-app-sg"
  })
}

# EC2 Instance - SINGLE DEFINITION
# Update the aws_instance resource in modules/app_server/main.tf
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  
  # IAM Instance Profile
  iam_instance_profile = var.iam_instance_profile != "" ? var.iam_instance_profile : ""
  
  # Security Groups
  vpc_security_group_ids = [aws_security_group.app_server.id]
  
  # User Data with database connection
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd mysql python3 python3-pip
              systemctl start httpd
              systemctl enable httpd
              
              # Create a simple PHP/Python page with database info
              cat > /var/www/html/index.html <<EOL
              <!DOCTYPE html>
              <html>
              <head>
                  <title>Chewbacca Medical - Lab 3A</title>
                  <style>
                      body { font-family: Arial, sans-serif; margin: 40px; }
                      .container { max-width: 800px; margin: 0 auto; }
                      .info { background: #f5f5f5; padding: 20px; border-radius: 5px; }
                      .db-info { background: #e8f4f8; padding: 15px; margin-top: 20px; }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <h1>🦊 Chewbacca Medical Application</h1>
                      <div class="info">
                          <h2>Lab 3A: Multi-Region Architecture</h2>
                          <p><strong>Region:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/region)</p>
                          <p><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
                      </div>
                      <div class="db-info">
                          <h3>📊 Database Connection</h3>
                          <p><strong>Database Endpoint:</strong> ${var.rds_endpoint}</p>
                          <p><strong>Status:</strong> Connected to Tokyo RDS</p>
                      </div>
                  </div>
              </body>
              </html>
              EOL
              
              # Test database connection (optional)
              cat > /tmp/test_db.py <<PYTHON
              #!/usr/bin/env python3
              import socket
              import sys
              
              # Simple connection test
              db_host = "${var.rds_endpoint}".split(":")[0]
              db_port = 3306
              
              try:
                  sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                  sock.settimeout(5)
                  result = sock.connect_ex((db_host, db_port))
                  if result == 0:
                      print(f"✓ Database connection to {db_host}:{db_port} successful")
                  else:
                      print(f"✗ Database connection failed (port closed)")
                  sock.close()
              except Exception as e:
                  print(f"✗ Database connection error: {e}")
              PYTHON
              
              python3 /tmp/test_db.py >> /var/www/html/db-test.txt
              
              # Restart Apache
              systemctl restart httpd
              EOF
  
  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-app-server"
  })
}
