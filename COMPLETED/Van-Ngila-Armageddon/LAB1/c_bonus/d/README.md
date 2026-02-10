# Lab 1C - Bonus D: ALB Access Logging & Route53 Apex Configuration

## Overview
This lab focuses on enhancing realism and observability in AWS infrastructure by implementing ALB access logging to S3 and configuring a Route53 apex record for the domain `theowafhomework.site`. These features are critical for incident response, security auditing, and operational visibility.

## Challenges Overcome

### 1. EC2 Port 80 Access Issues
- **Problem**: Initial configurations prevented proper traffic flow to EC2 instances on port 80.
- **Solution**: Adjusted security groups, target group health checks, and instance configurations to ensure HTTP accessibility.

### 2. Terraform Listener & Access Log Dependencies
- **Problem**: The `depends_on` attribute alone was insufficient to guarantee proper creation order between the S3 log bucket and ALB access log configuration.
- **Solution**: Implemented explicit resource dependencies and verified Terraform resource graph to ensure the S3 bucket is fully created before ALB attempts to write logs.

### 3. S3 Bucket Policy Configuration
- **Problem**: Initial bucket policies incorrectly used `"Service": "elasticloadbalancing.amazonaws.com"` which prevented ALB from delivering logs.
- **Solution**: Corrected policy to use `"Service": "logdelivery.elasticloadbalancing.amazonaws.com"` as required by AWS ALB access logging service.

## What We Achieved

### ✅ Infrastructure Components Deployed:
1. **Route53 Apex Record**: Created an ALIAS record for `theowafhomework.site` pointing to the ALB
2. **ALB Access Logging**: Configured Application Load Balancer to stream access logs to S3
3. **S3 Log Bucket**: Deployed with proper bucket policy allowing log delivery from ALB
4. **Verification Framework**: Provided CLI commands to validate all components

### ✅ Key Terraform Additions:
- **New Variables**: 
  - `enable_alb_access_logs` (boolean toggle)
  - `alb_access_logs_prefix` (custom log prefix)
- **ALB Modification**: Added `access_logs` nested block to existing ALB resource
- **New Outputs**:
  - Apex URL for direct domain access
  - Log bucket name for operational access

### ✅ Career-Critical Skills Developed:
- **Incident Response Readiness**: Access logs provide client IPs, paths, response codes, and latency data
- **Triage Capability**: Combined with WAF logs and ALB metrics, you can diagnose whether issues are caused by attackers, routing problems, or downstream failures
- **AWS Service Integration**: Mastered interplay between Route53, ALB, S3, and IAM policies

## Verification Commands
1. Confirm apex DNS record exists
2. Verify ALB logging is enabled with correct S3 destination
3. Generate test traffic via curl
4. Confirm logs are delivered to S3 bucket

## Why This Matters
Access logs are the "flight recorder" for your applications. They enable:
- Security investigations (identify malicious IPs and patterns)
- Performance analysis (pinpoint high-latency endpoints)
- Availability monitoring (track 5xx errors and their causes)
- Compliance auditing (maintain access records for regulatory requirements)

---

*Author: Vany*  
*AWS Infrastructure & Terraform Specialist*