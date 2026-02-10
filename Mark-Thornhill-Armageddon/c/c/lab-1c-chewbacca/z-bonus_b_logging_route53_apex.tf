data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}

# 1. The S3 Bucket for ALB Logs
resource "aws_s3_bucket" "chewbacca_alb_logs_bucket01" {
  count         = var.is_lab_active ? 1 : 0
  bucket        = "lew-alb-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Allows terraform destroy to work even if logs exist
}

# 2. The Required Bucket Policy for ELB Logging
resource "aws_s3_bucket_policy" "allow_alb_logging" {
  count  = var.is_lab_active ? 1 : 0
  bucket = aws_s3_bucket.chewbacca_alb_logs_bucket01[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn # AWS = "arn:aws:iam::582319560869:root" # ELB Account ID for ap-northeast-1
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.chewbacca_alb_logs_bucket01[0].arn}/${var.alb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}

# 3. Route 53 Apex Record (ALIAS to ALB)
resource "aws_route53_record" "apex" {
  count   = var.is_lab_active ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id # Ensure this matches your zone resource name
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.chewbacca_alb01[0].dns_name
    zone_id                = aws_lb.chewbacca_alb01[0].zone_id # ALB Hosted Zone ID
    evaluate_target_health = true
  }
}