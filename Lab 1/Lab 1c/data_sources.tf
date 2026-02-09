# data_sources.tf
data "aws_vpc" "chewbacca_vpc01" {
  tags = {
    Name = "${var.project_name}-vpc01"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.chewbacca_vpc01.id]
  }
  
  tags = {
    Tier = "public"
  }
}

data "aws_instance" "chewbacca_ec2" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-ec201"]
  }
}

# Add to data_sources.tf
data "aws_security_group" "chewbacca_ec2_sg01" {
  filter {
    name   = "tag:Name"
    values = ["sg-ec2-${var.project_name}"]  # Adjust based on your actual tag
  }
}

data "aws_security_group" "chewbacca_alb_sg01" {
  id = "sg-0e4cdce0965e88751"  # Your ALB SG ID
}

# OR by name if tagged
data "aws_security_group" "chewbacca_alb_sg01" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-alb-sg01"]  # Or whatever name you used in Lab 1
  }
}