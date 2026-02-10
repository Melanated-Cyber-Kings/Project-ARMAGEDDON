#from Perplexity
resource "aws_lambda_function" "rds_rotation" {
  function_name = "${var.env_prefix}-rds-secret-rotation"
  role          = aws_iam_role.rds_rotation_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30

  filename         = "${path.module}/rds-rotation.zip"      # Zip with the AWS RDS rotation blueprint
  source_code_hash = filebase64sha256("${path.module}/rds-rotation.zip")

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = var.lambda_security_group_ids
  }



#   environment {
#     variables = {
#       SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${var.region}.amazonaws.com"
#     }
#   }
}

resource "aws_iam_role" "rds_rotation_role" {
  name               = "${var.env_prefix}-rds-rotation-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.rds_rotation_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_secretsmanager" {
  role       = aws_iam_role.rds_rotation_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "lambda_rds" {
  role       = aws_iam_role.rds_rotation_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.rds_rotation_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_permission" "allow_secrets_manager" {
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_rotation.function_name
  principal     = "secretsmanager.amazonaws.com"
}

resource "aws_secretsmanager_secret_rotation" "rds_rotation" {
  secret_id           = var.secret_id
  rotation_lambda_arn = aws_lambda_function.rds_rotation.arn

  rotation_rules {
    automatically_after_days = 1
  }

  # ADD THIS - Forces clean state on apply
  lifecycle {
    ignore_changes = [rotation_rules]
  }
}