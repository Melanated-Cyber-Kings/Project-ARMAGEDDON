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
        Action = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:${var.env_prefix}/rds/mysql*"
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