# SNS Topic for Alarms
resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-alarms-topic"

  tags = {
    Name        = "${var.project_name}-alarms-topic"
    Project     = var.project_name
    Environment = var.environment
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-lambda-role"
    Project     = var.project_name
    Environment = var.environment
  }
}

# IAM Policy for Lambda
resource "aws_iam_policy" "lambda" {
  name        = "${var.project_name}-lambda-policy"
  description = "Policy for incident response Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:*:*:parameter/lab1b/*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:RebootDBInstance",
          "rds:StartDBInstance",
          "rds:StopDBInstance"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "sns:Publish"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

# Lambda Function for Incident Response
resource "aws_lambda_function" "incident_response" {
  function_name = "${var.project_name}-incident-response"
  description   = "Responds to database connectivity failures"

  runtime = "python3.9"
  handler = "lambda_function.lambda_handler"
  timeout = 30

  filename         = "${path.module}/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")

  role = aws_iam_role.lambda.arn

  environment {
    variables = {
      DB_INSTANCE_ID = var.db_instance_id
      REGION         = var.region
      PROJECT_NAME   = var.project_name
    }
  }

  tags = {
    Name        = "${var.project_name}-incident-response"
    Project     = var.project_name
    Environment = var.environment
  }
}

# SNS Subscription for Lambda
resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.incident_response.arn
}

# Lambda Permission for SNS
resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.incident_response.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alarms.arn
}