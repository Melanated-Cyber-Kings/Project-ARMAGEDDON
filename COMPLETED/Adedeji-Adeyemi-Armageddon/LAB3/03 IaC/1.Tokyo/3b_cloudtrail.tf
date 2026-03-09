# resource "aws_cloudtrail" "global_compliance_trail" {
#   name                          = "medical-global-trail"
#   s3_bucket_name                = "class-lab3-200819971986"
#   include_global_service_events = true
#   is_multi_region_trail         = true
#   enable_log_file_validation    = true
#   depends_on = [aws_s3_bucket_policy.allow_cloudfront_logging]
# }

resource "aws_cloudtrail" "global_compliance_trail" {
  name                          = "medical-global-trail"
  # FIX: Point to the dynamic bucket resource name
  s3_bucket_name                = aws_s3_bucket.audit_log_vault.id
  
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
}
