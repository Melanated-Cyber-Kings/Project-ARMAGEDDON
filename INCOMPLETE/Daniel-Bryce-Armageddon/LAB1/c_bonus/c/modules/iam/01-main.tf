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
          "logs:PutMetricFilter",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",  # added
          "logs:FilterLogEvents",     # added
          "SNS:ListTopics",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DescribeAlarms",
          "rds:DescribeDBInstances",
          "cloudwatch:PutMetricData",
          "ssm:DescribeInstanceInformation",  # Added for verification
          "ec2:DescribeVpcEndpoints"          # Added for verification
          #"logs:CloudWatchLogsFullAccess"
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
                  "secretsmanager:DescribeSecret",
                  "secretsmanager:ListSecrets"
        ]
        Resource = ["arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:lab-1c/rds/mysql*",
                    "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:lab*/rds/mysql*"
        ]
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

resource "aws_iam_role_policy_attachment" "cw_agent" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

#################################################################
# Policy for SSM Parameter Store access
resource "aws_iam_policy" "ssm_read" {
  name        = "${var.env_prefix}-ssm-read-policy"
  description = "Read access to SSM Parameter Store"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${var.region}:${var.account_id}:parameter/lab/db/*",
          "arn:aws:ssm:${var.region}:${var.account_id}:parameter/lab/*"
        ]
      }
    ]
  })
}

# Policy for CloudWatch Logs
resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "${var.env_prefix}-cloudwatch-logs-policy"
  description = "Write access to CloudWatch Logs"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",     # Added for verification
          "logs:FilterLogEvents"        # Added for verification
        ]
        Resource = [
          "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/ec2/lab-rds-app:*",
          "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/ec2/lab-rds-app",
          "arn:aws:logs:${var.region}:${var.account_id}:log-group:*"
        ]
      }
    ]
  })
}


# Attach policies to EC2 role
resource "aws_iam_role_policy_attachment" "ssm_read" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = aws_iam_policy.ssm_read.arn
}

# resource "aws_iam_role_policy_attachment" "secrets_read" {
#   role       = aws_iam_role.ec2_secrets_role.name
#   policy_arn = aws_iam_policy.secrets_read.arn
# }

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}

# Add policy for SSM Session Manager
resource "aws_iam_policy" "ssm_session_manager" {
  name        = "${var.env_prefix}-ssm-session-manager-policy"
  description = "Permissions for SSM Session Manager"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:GetMessages",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:SendReply"
        ]
        Resource = "*"
      }
      # {
      #   Effect = "Allow"
      #   Action = "kms:Decrypt"
      #   Resource = var.kms_key_arn
      # }
    ]
  })
}

# Session manager
resource "aws_iam_role_policy_attachment" "ssm_session_manager" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = aws_iam_policy.ssm_session_manager.arn
}

# Ajoutez aussi la politique AWS Managed pour SSM (recommandée)
resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
