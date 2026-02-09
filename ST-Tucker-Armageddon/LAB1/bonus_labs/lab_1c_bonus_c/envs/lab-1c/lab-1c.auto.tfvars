#############################################
# Lab 1C — Environment Variables
#############################################

# --------------------
# Global / Naming
# --------------------
env_prefix = "lab-1c"

region     = "ap-northeast-1"
account_id = "261519058382"

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

# Lab default: multiple availibility zones.
rds_multi_az = false

# --------------------
# Alerting / SNS
# --------------------
#alert_email = "selacious@outlook.com"

alert_email = "tucker.stacyh@gmail.com"

# --------------------
# Secrets Rotation (Phase-4)
# --------------------
# Leave null until AFTER:
#  - env stack deployed
#  - real RDS endpoint exists
#  - rotation Lambda deployed

# rotation_lambda_arn = null
# rotation_days       = 30

##############################################
# Project Name
##############################################

project = "Armageddon"
##############################################

###############################################################################
# Bonus C — ALB + TLS + WAF + Observability
###############################################################################
#domain_name = "chewbacca-growl.com"
domain_name   = "devlab405.click"
app_subdomain = "app"

# Here we are using an existing Route 53 hosted zone. If you wanted to create a new
# hosted zone, you would set dns_mode = "route53_managed" and provide the appropriate
# domain_name above.

# dns_mode options:
#   - route53_managed  : Terraform creates hosted zone + records
#   - route53_existing : Hosted zone already exists in Route53 (provide zone id)
#   - external         : DNS is outside Route53; Terraform outputs validation records

dns_mode = "route53_existing"

# If using an existing Route 53 hosted zone, provide the hosted zone ID here.
# You can find this in the Route 53 console.

route53_hosted_zone_id = "Z103851437PNELROEQ0AM"


app_port                   = 80
alb_5xx_threshold          = 10
alb_5xx_period_seconds     = 300
alb_5xx_evaluation_periods = 1

# WAF Logging Configuration
waf_log_destination              = "cloudwatch"
waf_log_retention_days           = 14
enable_waf_sampled_requests_only = false
