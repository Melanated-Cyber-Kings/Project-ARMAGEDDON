







Purpose

Allow the EC2 instance to securely retrieve database credentials from AWS Secrets Manager without storing any credentials on the instance.

This establishes identity-based trust between EC2 and Secrets Manager and eliminates the need for static access keys.

Terraform Actions
1️⃣ Create an IAM role for EC2
resource "aws_iam_role" "ec2_secrets_role" {
  name = "ec2-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}


This role defines who is allowed to assume it.
Only EC2 instances can use this role.
