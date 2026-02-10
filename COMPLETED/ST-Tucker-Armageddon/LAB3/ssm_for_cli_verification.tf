# 1. The Role itself
resource "aws_iam_role" "ssm_role" {
  name = "medical-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      },
    ]
  })
}

# 2. Attach the Managed Policy (The "Permissions")
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 3. The Instance Profile (The "Bridge" to EC2)
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "medical-ssm-profile"
  role = aws_iam_role.ssm_role.name
}





