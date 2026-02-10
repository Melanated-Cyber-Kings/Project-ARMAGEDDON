###############################################################################
# alb_access_logs.tf
# Module: ingress (Bonus D)
###############################################################################

# Here we set up an S3 bucket for ALB access logs, including the necessary permissions for the ALB to write logs to the bucket.
# We also ensure that the bucket has public access blocked to prevent unauthorized access to the logs.
# The ALB will write access logs to this bucket, which can be useful for monitoring and troubleshooting.
# If ALB access logging is enabled, ensure that the S3 bucket exists and has the correct policy allowing the ALB to write logs.
# The bucket should also have lifecycle policies to manage log retention, which can be added as needed.
# ALB access logs can be analyzed for traffic patterns, troubleshooting, and security monitoring.
#
# Reference: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
# Reference: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs-s3-bucket.html
# Reference: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs-bucket-policy.html

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "alb_logs" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = "${local.name_prefix}-alb-logs-${data.aws_caller_identity.current.account_id}"

  # We set force_destroy to true to allow Terraform to delete the bucket even if it contains objects (logs).
  # In a production environment, you *should* set this to false to prevent accidental deletion of logs.
  # For this lab, we will set it to true for convenience, but in a real-world scenario, you should be cautious with this setting.
  # Reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket#force_destroy
  # Note: If you set force_destroy to true, be aware that all logs in the bucket will be deleted when the bucket is destroyed.

  # If you want to manage log retention, you can add a lifecycle rule to the bucket to automatically delete logs after a certain period. For example:
  # lifecycle_rule {
  #   id      = "log-retention"
  #   enabled = true
  #   expiration {
  #     days = 30
  #   }
  # }


  force_destroy = true

  tags = {
    Name = "${local.name_prefix}-alb-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Policy to allow the ALB to write access logs to the S3 bucket. This policy grants the 
# necessary permissions for the ALB to put objects (logs) into the bucket and to check the bucket's ACL.

data "aws_iam_policy_document" "alb_logs" {
  count = var.enable_alb_access_logs ? 1 : 0

  statement {
    sid = "AWSLogDeliveryWrite"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.alb_logs[0].arn}/${var.alb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.alb_logs[0].arn]
  }
}


resource "aws_s3_bucket_policy" "alb_logs" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id
  policy = data.aws_iam_policy_document.alb_logs[0].json
}
