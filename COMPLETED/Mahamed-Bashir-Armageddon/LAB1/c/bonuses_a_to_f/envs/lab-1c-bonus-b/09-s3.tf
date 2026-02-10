
module "s3_logs" {
  source = "../../modules/s3"

  bucket_name       = "${local.name_prefix}-alb-logs-${var.account_id}"
  name_prefix       = local.name_prefix
  force_destroy     = true
  versioning_status = "Suspended"
  
  tags = {
    Purpose = "ALB Access Logs"
  }
}

# 2. The Policy (Allows ELB to write to it)
resource "aws_s3_bucket_policy" "alb_logging" {
  bucket = module.s3_logs.bucket_id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowELBLogDelivery"
        Effect = "Allow",
        Principal = {
          # Tokyo ELB Account ID
          AWS = "arn:aws:iam::582318560864:root" 
        },
        Action = "s3:PutObject",
        Resource = "${module.s3_logs.bucket_arn}/*"
      }
    ]
  })
}