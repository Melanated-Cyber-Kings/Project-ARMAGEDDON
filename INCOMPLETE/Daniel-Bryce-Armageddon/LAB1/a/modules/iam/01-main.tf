# IAM Role for EC2
resource "aws_iam_role" "ec2_secrets_role" {
  name = "${var.env_prefix}-ec2-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2_policy"
  role = aws_iam_role.ec2_secrets_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
# Custom Policy to read Secrets Manager secret
resource "aws_iam_policy" "ec2_secrets_policy" {
  name        = "${var.env_prefix}-EC2ReadRDSSecret"
  description = "Allow EC2 to read lab/rds/mysql secret"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSpecificSecret"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue",
                  "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:lab-1a/rds/mysql*"
      },
      {
        Sid    = "AllowKMSDecrypt"
        Effect = "Allow"
        Action = "kms:Decrypt"
        Resource = var.kms_key_arn
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "secrets_attach" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = aws_iam_policy.ec2_secrets_policy.arn
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.env_prefix}-ec2-secrets-profile"
  role = aws_iam_role.ec2_secrets_role.name
}
