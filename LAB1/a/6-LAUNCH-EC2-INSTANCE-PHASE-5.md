










Phase 5 — Launch EC2 Instance
Purpose

Deploy the compute layer for your lab application. This EC2 instance will host the Python Flask web app that connects to the RDS database using credentials retrieved securely from Secrets Manager.

At this point, the network, IAM role, and security groups are already set up, so the instance can safely communicate with the database once the app is installed.

Terraform Actions
1️⃣ Launch EC2 instance
resource "aws_instance" "ec2_app" {
  ami                         = "ami-0xxxxxxx"   # Amazon Linux 2023
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet1.id  # from Phase 1
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  key_name                    = "your-key-pair"  # optional, if SSH needed

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y python3 python3-pip git
              pip3 install flask pymysql boto3
              EOF

  tags = {
    Name = "lab-ec2-app"
  }
}


Key references in this Terraform code:

iam_instance_profile → attaches the IAM role from Phase 4

vpc_security_group_ids → attaches the EC2 security group from Phase 2

subnet_id → ensures the EC2 instance is in your custom VPC (Phase 1)

user_data → bootstraps the instance with required software (Python, pip, Flask) to run the lab application
