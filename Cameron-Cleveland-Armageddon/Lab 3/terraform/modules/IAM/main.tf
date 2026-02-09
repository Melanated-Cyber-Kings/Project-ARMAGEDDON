# IAM Role for EC2 instances to use SSM
resource "aws_iam_role" "ssm_role" {
  name = "${var.name_prefix}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# Attach AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Optional: Policy for S3 access if your app needs it
resource "aws_iam_policy" "s3_read_only" {
  count = var.enable_s3_access ? 1 : 0

  name        = "${var.name_prefix}-s3-read"
  description = "Read-only access to specific S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  count = var.enable_s3_access ? 1 : 0

  role       = aws_iam_role.ssm_role.name
  policy_arn = aws_iam_policy.s3_read_only[0].arn
}

# Instance Profile to attach role to EC2
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.name_prefix}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}