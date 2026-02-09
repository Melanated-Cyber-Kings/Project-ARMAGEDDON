# ec2/main.tf
# resource "aws_instance" "ec2" {
#   ami                    = "ami-03d1820163e6b9f5d"
#   instance_type          = var.instance_type
#   subnet_id              = var.subnet_id
#   vpc_security_group_ids = var.security_group_ids
#   associate_public_ip_address = true

#   user_data = file("${path.root}/scripts/user_data.sh")

#   tags = {
#     Name = "${var.env_prefix}-ec2-app"
#   }
# }

# ec2/main.tf
resource "aws_instance" "ec2" {
  ami                    = "ami-03d1820163e6b9f5d"
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  associate_public_ip_address = true


 
  
 
  iam_instance_profile = var.instance_profile_name
  

  
  # Use templatefile to inject dynamic RDS host, secret ID, and region
user_data = templatefile(var.user_data_path, {
    rds_host  = var.rds_host          # Dynamic RDS endpoint from RDS module
    secret_id = var.secret_id         # Secret ID from Secrets Manager
    region    = var.region            # AWS region
  })

  tags = {
    Name = "${var.env_prefix}-ec2-app"
  }


# ✅ Ensure replacement if IAM instance profile changes
  lifecycle {
  create_before_destroy = true
  }
}