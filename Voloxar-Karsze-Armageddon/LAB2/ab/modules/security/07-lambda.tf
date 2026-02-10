# Add to your Lambda (if in VPC) or create a new security group
resource "aws_security_group" "lambda_to_rds" {
  vpc_id = var.vpc_id  # Your VPC
  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.rds_sg.id]
  }

  tags = {
    Name = "${var.env_prefix}-rotation-lambda-rds-sg"
  }
}


resource "aws_security_group" "lambda_to_secrets" {
  name        = "lambda-to-secrets"
  description = "Lambda egress to Secrets Manager endpoint"
  vpc_id      = var.vpc_id

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc_endpoint_sg.id]
  }

  tags = {
    Name = "${var.env_prefix}-rotation-lambda-secrets-sg"
  }
}