#############################################
# Lab 1C — Environment Variables
#############################################

# --------------------
# Global / Naming
# --------------------
env_prefix = "lab-1c"

region     = "ap-northeast-1"
account_id = "261519058382"

project = "Armageddon"

kms_key_arn = "arn:aws:kms:ap-northeast-1:261519058382:key/0907dcba-09de-87dc-65ba-ab0987654321"

tags = {
  Lab     = "Lab-1C"
  Project = "Armageddon"
}

# --------------------
# Networking
# --------------------
vpc_cidr_block = "10.30.0.0/16"

public_subnet_cidr   = "10.30.1.0/24"
public_subnet_cidr_2 = "10.30.2.0/24"

private_subnet_cidr_1 = "10.30.11.0/24"
private_subnet_cidr_2 = "10.30.12.0/24"

avail_zone_1 = "ap-northeast-1a"
avail_zone_2 = "ap-northeast-1c"

rtb_public_cidr = "0.0.0.0/0"

# --------------------
# EC2
# --------------------
instance_type = "t3.micro"

# --------------------
# RDS
# --------------------
db_name = "labdb"

# For MySQL, the default port is 3306. If you choose a different 
# database engine, make sure to update the port accordingly.
db_port = 3306

# Lab default: single AZ unless overridden
rds_multi_az = false

# --------------------
# Secrets + DB Credentials (migrated from /secrets into env)
# --------------------
db_username = "appuser"
# db_password = "REPLACE_WITH_STRONG_PASSWORD"
# We are using a hardcoded password here for simplicity, but in production, you should use a secure method to manage secrets, such as AWS Secrets Manager or AWS Systems Manager Parameter Store.
# For the purposes of this lab, ensure that the password meets AWS RDS requirements (at least 8 characters, including uppercase, lowercase, numbers, and special characters).
# Please replace "StrongPassword123!" with a secure password of your choice before deploying the infrastructure.
# Note: In a real-world scenario, never hardcode sensitive information like database credentials in your code or configuration files. Always use secure secret management practices.


db_password = "StrongPassword123!"

# --------------------
# Secrets Rotation (grading requires enabled)
# --------------------
enable_rotation     = true
rotation_days       = 30
manage_secret_value = true

# --------------------
# Alerting / SNS
# --------------------
alert_email = "selacious@outlook.com"

# --------------------
#  — ALB + TLS + WAF + Observability
# --------------------
domain_name   = "devlab405.click"
app_subdomain = "app"

dns_mode = "route53_existing"

route53_hosted_zone_id = "Z103851437PNELROEQ0AM"

app_port                   = 80
alb_5xx_threshold          = 10
alb_5xx_period_seconds     = 300
alb_5xx_evaluation_periods = 1

# --------------------
# WAF Logging Configuration
# --------------------
waf_log_destination = "cloudwatch"

waf_log_retention_days           = 14
enable_waf_sampled_requests_only = false
