########################################
1. Setup the Tokyo Route
########################################

Open Tokyo\tokyo_tgw.tf 
- Temporarily change the route to use your variable instead of the remote state. 
- This allows Tokyo to plan without a São Paulo state file.

resource "aws_ec2_transit_gateway_route" "shinjuku_to_liberdade_tgw_static" {
  destination_cidr_block         = "10.102.0.0/16" 
  # Switch from data.remote_state to the variable below:
  transit_gateway_attachment_id  = var.sa_paulo_tgw_id 
  transit_gateway_route_table_id = aws_ec2_transit_gateway.shinjuku_tgw01.propagation_default_route_table_id
}

########################################
2. Workaround  S3 Bucket Collision
#########################################

S3 bucket names must be unique across the entire world, and across all acounts.

The solution: 
Update 3b_tokyo_logs.tf file. I recommend appending a random string or a more specific project prefix to the bucket name.
Terraform

# Change the name to something unique
resource "aws_s3_bucket" "audit_log_vault" {
  bucket = "medical-vault-audit-logs-sprint3-${random_id.bucket_suffix.hex}" 
  # OR manually change it to something like:
  # bucket = "shinjuku-audit-vault-2026-v1"
}

# Add this to help with uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

##################################################
3. Fix the TGW ID Error (The "Dummy" Problem)
##################################################

AWS validates the format of the Attachment ID before it even tries to create the route. tgw-attach-12345 is too short/malformed for AWS's API to accept, even as a placeholder.

Two options to bypass this validation error so you can get your state file created.
Option A: Use a valid-looking dummy ID

AWS expects an ID that looks like tgw-attach- followed by 17 hexadecimal characters. Try this command instead:
terraform apply -var="sa_paulo_tgw_id=tgw-attach-1234567890abcdef0"
Option B: Target around the Route (Recommended)

Since the goal of the "Manual Bridge" is just to get the Tokyo state file to exist so São Paulo can read the RDS/SSM info, just don't build the route yet.

Run this command to build everything except the failing route:
terraform apply -target=aws_db_instance.shinjuku_medical_db -target=aws_iam_instance_profile.ssm_profile -target=aws_route53_zone.main -target=aws_ec2_transit_gateway.shinjuku_tgw01



#######################################
3. Revised Execution:
#######################################

Change the Bucket Name in 3b_tokyo_logs.tf.

Run the Targeted Apply (Option B above). This will ignore the route and focus on getting the RDS and SSM Profile live.

Go to São Paulo and run terraform apply. It will now see the Tokyo state file (with the new bucket name and RDS info) and succeed.

Capture the REAL TGW ID from the São Paulo output.

Return to Tokyo and run a full terraform apply using the real ID for sa_paulo_tgw_id.

terraform apply -var="sa_paulo_tgw_id=tgw-attach-05cc331c9a7835b14" -auto-approve

#######################################
3. Troubleshooting:
#######################################

│ Error: creating CloudTrail Trail (medical-global-trail): operation error CloudTrail: CreateTrail, https response error StatusCode: 400, RequestID: 4d2ca085-eff1-48af-8a7b-c895773abc82, InsufficientS3BucketPolicyException: Incorrect S3 bucket policy is detected for bucket: medical-vault-audit-logs-sprint3-v1-200819971986
│
│   with aws_cloudtrail.global_compliance_trail,
│   on 3b_cloudtrail.tf line 10, in resource "aws_cloudtrail" "global_compliance_trail":
│   10: resource "aws_cloudtrail" "global_compliance_trail" {
│
terraform refresh
fixed the sync and race condition issue

#######################################
4. Garbage Collection and Destroy
#######################################

terraform destroy -auto-approve -refresh=false