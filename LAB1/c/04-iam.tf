############################################
# IAM Role + Instance Profile for EC2
############################################

# Explanation: this role lets EC2 assume permissions safely.
resource "aws_iam_role" "ec2_role01" {
  name = "${local.name_prefix}-ec2-role01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Explanation: These policies are allowing Session Manger access to EC2.
resource "aws_iam_role_policy_attachment" "ec2_ssm_attach" {
  role       = aws_iam_role.ec2_role01.name
  policy_arn  = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Explanation: EC2 must read secrets/params during recovery—give it access (students should scope it down).
resource "aws_iam_role_policy_attachment" "ec2_secrets_attach" {
  role      = aws_iam_role.ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSecretsManagerClientReadOnlyAccess" # TODO: student replaces w/ least privilege
}

# Explanation: CloudWatch logs are the “ship’s black box”—you need them when things explode.
resource "aws_iam_role_policy_attachment" "ec2_cw_attach" {
  role      = aws_iam_role.ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Explanation: Instance profile is the harness that straps the role onto the EC2 like bandolier ammo.
resource "aws_iam_instance_profile" "instance_profile01" {
  name = "${local.name_prefix}-instance-profile01"
  role = aws_iam_role.ec2_role01.name
}

# resource "aws_iam_role_policy" "cloudwatch_put_metrics" {
#   name = "CloudWatchPutMetricsPolicy"
#   role = aws_iam_role.ec2_role01.name # Replace with your actual role name variable

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = "cloudwatch:PutMetricData"
#         Resource = "*"
#         Condition = {
#           StringEquals = {
#             "cloudwatch:namespace" = "CustomDatabaseMetrics" # Optional: Restrict to your specific namespace
#           }
#         }
#       }
#     ]
#   })
# }

############################################
# IAM Policy: Allow EC2 to Read Config & Secrets
############################################

resource "aws_iam_role_policy" "ec2_app_permissions" {
  name = "${local.name_prefix}-app-permissions"
  role = aws_iam_role.ec2_role01.id

  # Requirement 7.3: No AccessDeniedException
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permissions for Parameter Store (Step 7.1)
        Action   = [
          #"ssm:GetParameter",
          "ssm:GetParameters",
          #"ssm:GetParameterHistory"
        ]
        Effect   = "Allow"
        Resource = "*" # In production, restrict to your specific Parameter ARNs
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*" # Replace with your specific KMS Key ARN if known
   },
      {
        # Permissions for Secrets Manager (Step 7.2)
        Action   = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = "*" # In production, restrict to your Secret ARN
      },
      # {
      #   # Permissions to pull Flask app and dependencies from S3
      #   Action   = [
      #     "s3:GetObject",
      #     "s3:ListBucket"
      #   ]
      #   Effect   = "Allow"
      #   Resource = [
      #     aws_s3_bucket.app_dependencies.arn,
      #     "${aws_s3_bucket.app_dependencies.arn}/*"
      #   ]
      # },
      {
        # Permissions for CloudWatch Logs (Step 7.4)
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:FilterLogEvents",
          "cloudwatch:DescribeAlarms",
          "SNS:ListSubscriptionsByTopic",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

