resource "aws_cloudtrail" "global_compliance_trail" {
  name                          = "medical-global-trail"
  s3_bucket_name                = "arma-lab3-bucket"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true # Critical for proof of non-tampering
  depends_on                    = [aws_s3_bucket_policy.allow_cloudfront_logging]
}