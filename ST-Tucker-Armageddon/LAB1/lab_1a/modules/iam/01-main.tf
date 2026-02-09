###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: iam
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

data "aws_iam_policy_document" "ec2_secrets_policy" {

  statement {
    sid    = "AllowReadSpecificSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [
      var.secret_arn
    ]
  }

  statement {
    sid    = "AllowDecryptForSecret"
    effect = "Allow"

    actions = [
      "kms:Decrypt"
    ]

    resources = [
      var.kms_key_arn
    ]
  }
}

resource "aws_iam_role" "ec2_secrets_role" {
  name = "${var.env_prefix}-ec2-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_secrets_policy" {
  name   = "${var.env_prefix}-ec2-secrets-policy"
  policy = data.aws_iam_policy_document.ec2_secrets_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = aws_iam_policy.ec2_secrets_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.env_prefix}-ec2-profile"
  role = aws_iam_role.ec2_secrets_role.name
}
