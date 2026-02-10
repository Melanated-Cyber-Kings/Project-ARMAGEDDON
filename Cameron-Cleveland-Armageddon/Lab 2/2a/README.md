# Lab 2A — Origin Cloaking + CloudFront as the Only Public Ingress

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Key Principles](#key-principles)
- [Infrastructure Requirements](#infrastructure-requirements)
- [Terraform Implementation](#terraform-implementation)
- [Verification Checklist](#verification-checklist)
- [Student Deliverables](#student-deliverables)
- [Reflection Questions](#reflection-questions)
- [Troubleshooting Guide](#troubleshooting-guide)

## Architecture Overview

```
Internet → CloudFront (+ WAF) → ALB (locked to CloudFront) → Private EC2 → RDS
```

### Key Constraints
- ✅ **Only CloudFront is publicly reachable**
- ✅ **ALB is "cloaked"** - Internet-facing but inaccessible directly
- ✅ **WAF enforcement happens at CloudFront edge**
- ✅ **DNS points to CloudFront, not ALB**

## Key Principles

### What "Origin Cloaking" Means
In production environments, you never expose backend infrastructure directly to the internet. Instead:
1. **CloudFront** becomes the **only public ingress point**
2. **ALB** remains internet-facing (CloudFront needs to reach it) but is protected by:
   - Security Group restrictions (only CloudFront IPs)
   - Secret header validation (only CloudFront adds it)
3. **WAF moves from ALB to CloudFront** for edge protection

### Why This Matters
| Pattern | Problem | Solution |
|---------|---------|----------|
| Exposed ALB | DDoS, credential stuffing, scanning | CloudFront absorbs attacks |
| No header validation | Anyone can bypass CloudFront | Secret header requirement |
| ALB-scoped WAF | Expensive, less effective | Edge-scoped WAF = cheaper, faster |
| Direct access | Security incidents, data leakage | Complete origin cloaking |

## Infrastructure Requirements

### Prerequisites (From Lab 1C)
- ✅ `aws_lb.chewbacca_alb01`
- ✅ `aws_security_group.chewbacca_alb_sg01`
- ✅ Route53 zone (`chewbacca-growl.com`)
- ✅ WAF (will be replaced with CLOUDFRONT-scoped)

### New Components
1. **CloudFront Distribution** (us-east-1 certificate requirement)
2. **CloudFront-Origin Security Group Rule**
3. **Secret Header Validation**
4. **CloudFront-scoped WAF**
5. **Route53 CloudFront Aliases**

## Terraform Implementation

### File Structure
```
terraform-lab-2a/
├── providers.tf                 # us-east-1 provider for CloudFront certs
├── lab2_cloudfront_origin_cloaking.tf  # SG rules + header validation
├── lab2_cloudfront_alb.tf              # CloudFront distribution
├── lab2_cloudfront_shield_waf.tf       # CloudFront-scoped WAF
├── lab2_cloudfront_r53.tf              # Route53 CloudFront aliases
└── outputs.tf                          # CloudFront distribution ID, domain
```

### 0. CloudFront Certificate (us-east-1 Requirement)
**Critical:** CloudFront viewer certificates **must** be in us-east-1 (N. Virginia).

```hcl
# providers.tf
provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

# ACM certificate in us-east-1 for CloudFront
resource "aws_acm_certificate" "cloudfront_cert" {
  provider          = aws.us-east-1
  domain_name       = "chewbacca-growl.com"
  validation_method = "DNS"
  
  subject_alternative_names = [
    "app.chewbacca-growl.com",
    "*.chewbacca-growl.com"
  ]
  
  lifecycle {
    create_before_destroy = true
  }
}

# Route53 validation for us-east-1 cert
resource "aws_route53_record" "cloudfront_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.chewbacca.zone_id
}

resource "aws_acm_certificate_validation" "cloudfront_cert" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.cloudfront_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_cert_validation : record.fqdn]
}
```

### 1. Origin Cloaking: ALB Security Group
**Only allow inbound traffic from CloudFront origin-facing IP ranges.**

```hcl
# lab2_cloudfront_origin_cloaking.tf
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# Replace existing ALB SG ingress rules
resource "aws_security_group_rule" "alb_cloudfront_https" {
  security_group_id = aws_security_group.chewbacca_alb_sg01.id
  type              = "ingress"
  description       = "Allow HTTPS from CloudFront origin-facing IPs"
  
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  
  # CRITICAL: Use CloudFront prefix list instead of CIDR blocks
  prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
}

# Remove any existing 0.0.0.0/0 rules on port 443
# Ensure no other ingress rules allow public access to port 443
```

### 2. Secret Header Validation
**Defense-in-depth: ALB requires a custom header only CloudFront adds.**

```hcl
# lab2_cloudfront_origin_cloaking.tf
# Create a random secret for the header value
resource "random_uuid" "origin_header_secret" {}

# ALB Listener Rule requiring the secret header
resource "aws_lb_listener_rule" "require_cloudfront_header" {
  listener_arn = aws_lb_listener.chewbacca_https.arn
  priority     = 1  # Higher priority than default
  
  action {
    type = "fixed-response"
    
    fixed_response {
      content_type = "text/plain"
      message_body = "403 Forbidden: Direct access not permitted"
      status_code  = "403"
    }
  }
  
  condition {
    # This is a CATCH-ALL rule that blocks everything
    path_pattern {
      values = ["/*"]
    }
  }
}

# Rule that allows traffic with the secret header
resource "aws_lb_listener_rule" "allow_cloudfront" {
  listener_arn = aws_lb_listener.chewbacca_https.arn
  priority     = 100  # Lower priority (checked after catch-all)
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chewbacca.arn
  }
  
  condition {
    # Only forward if the secret header is present and correct
    http_header {
      http_header_name = "X-Chewbacca-Growl"
      values           = [random_uuid.origin_header_secret.result]
    }
  }
}
```

### 3. CloudFront-scoped WAF
**WAF moves from REGIONAL (ALB) to CLOUDFRONT (global edge).**

```hcl
# lab2_cloudfront_shield_waf.tf
resource "aws_wafv2_web_acl" "cloudfront_waf" {
  name        = "chewbacca-cf-waf01"
  description = "CloudFront-scoped WAF for chewbacca-growl.com"
  scope       = "CLOUDFRONT"  # CRITICAL: Must be CLOUDFRONT, not REGIONAL
  
  default_action {
    allow {}
  }
  
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    
    override_action {
      none {}
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }
  
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "chewbacca-cf-waf01"
    sampled_requests_enabled   = true
  }
}

# Associate WAF with CloudFront in the distribution config
# This is done in the CloudFront resource below
```

### 4. CloudFront Distribution
**The public-facing entry point.**

```hcl
# lab2_cloudfront_alb.tf
resource "aws_cloudfront_distribution" "chewbacca_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "chewbacca-growl.com distribution"
  default_root_object = "index.html"
  
  # WAF association
  web_acl_id = aws_wafv2_web_acl.cloudfront_waf.arn
  
  # Origin: Your ALB
  origin {
    domain_name = aws_lb.chewbacca_alb01.dns_name
    origin_id   = "chewbacca-alb-origin"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    
    # Add the secret header to every request
    custom_header {
      name  = "X-Chewbacca-Growl"
      value = random_uuid.origin_header_secret.result
    }
  }
  
  # Default cache behavior
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "chewbacca-alb-origin"
    
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    
    # Forward all headers (needed for secret header)
    forwarded_values {
      query_string = true
      headers      = ["X-Chewbacca-Growl", "Host"]
      
      cookies {
        forward = "all"
      }
    }
    
    # Use WAF
    web_acl_id = aws_wafv2_web_acl.cloudfront_waf.arn
    
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }
  
  # Price class (US/Europe/All)
  price_class = "PriceClass_100"  # US/Canada/Europe
  
  # Viewer certificate (must be in us-east-1)
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  # Custom error responses (optional)
  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 403
    response_page_path    = "/error.html"
  }
  
  # Domain restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  # Aliases
  aliases = [
    "chewbacca-growl.com",
    "app.chewbacca-growl.com",
    "*.chewbacca-growl.com"
  ]
  
  tags = {
    Name = "chewbacca-distribution"
  }
}
```

### 5. Route53: Point Domain to CloudFront
**Update DNS to use CloudFront instead of ALB.**

```hcl
# lab2_cloudfront_r53.tf
# Apex domain (chewbacca-growl.com)
resource "aws_route53_record" "apex_cloudfront" {
  zone_id = aws_route53_zone.chewbacca.zone_id
  name    = "chewbacca-growl.com"
  type    = "A"
  
  alias {
    name                   = aws_cloudfront_distribution.chewbacca_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.chewbacca_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# App subdomain (app.chewbacca-growl.com)
resource "aws_route53_record" "app_cloudfront" {
  zone_id = aws_route53_zone.chewbacca.zone_id
  name    = "app.chewbacca-growl.com"
  type    = "A"
  
  alias {
    name                   = aws_cloudfront_distribution.chewbacca_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.chewbacca_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
```

## Verification Checklist

### 1. **Direct ALB Access Should Fail (403)**
```bash
# Get ALB DNS name from Terraform output
ALB_DNS=$(terraform output -raw alb_dns_name)

# Test direct access (should return 403)
curl -I "https://$ALB_DNS"
curl -v "https://$ALB_DNS" 2>&1 | grep -E "HTTP|< X-Chewbacca-Growl"
```

**Expected:**
```
HTTP/2 403
# OR
403 Forbidden: Direct access not permitted
```

### 2. **CloudFront Access Should Succeed (200)**
```bash
# Test via CloudFront
curl -I "https://chewbacca-growl.com"
curl -I "https://app.chewbacca-growl.com"

# With verbose output to see headers
curl -v "https://chewbacca-growl.com" 2>&1 | grep -E "HTTP/|CF-|X-Cache"
```

**Expected:**
```
HTTP/2 200
# OR
HTTP/2 301 → 200
X-Cache: Hit from cloudfront
```

### 3. **WAF Moved to CloudFront**
```bash
# Get WAF details
aws wafv2 get-web-acl \
  --name chewbacca-cf-waf01 \
  --scope CLOUDFRONT \
  --region us-east-1 \
  --query "WebACL.{Name:Name,ARN:ARN,Scope:Scope}"

# Verify CloudFront distribution references WAF
CF_ID=$(terraform output -raw cloudfront_distribution_id)
aws cloudfront get-distribution \
  --id $CF_ID \
  --query "Distribution.DistributionConfig.WebACLId"
```

**Expected:** WebACL ARN present, scope = "CLOUDFRONT"

### 4. **DNS Points to CloudFront**
```bash
# Check DNS resolution
dig chewbacca-growl.com A +short
dig app.chewbacca-growl.com A +short

# Should resolve to CloudFront (look for cloudfront.net domains)
nslookup chewbacca-growl.com | grep cloudfront
```

**Expected:** CloudFront anycast IPs (e.g., `13.32.0.0/15` range)

### 5. **Security Group Verification**
```bash
# Check ALB security group rules
ALB_SG_ID=$(terraform output -raw alb_security_group_id)
aws ec2 describe-security-groups \
  --group-ids $ALB_SG_ID \
  --query "SecurityGroups[0].IpPermissions" \
  --output json | jq '.[] | select(.FromPort==443)'

# Should show prefix list ID, not CIDR blocks
```

**Expected:** `PrefixListIds` with CloudFront prefix list, not `IpRanges` with `0.0.0.0/0`

### 6. **Secret Header Flow Test**
```bash
# Test that header is required
curl -H "X-Chewbacca-Growl: wrong-secret" "https://$ALB_DNS" -I
# Should still return 403

# Get the actual secret from Terraform state
SECRET_HEADER=$(terraform output -raw origin_header_secret)
echo "Secret header value: $SECRET_HEADER"
```

## Student Deliverables

### 1. **Terraform Artifacts**
- ✅ Complete Terraform code with all 5 components
- ✅ Working `providers.tf` with us-east-1 alias
- ✅ Validated ACM certificate in us-east-1
- ✅ No syntax errors in `terraform validate`

### 2. **Execution Evidence**
- `terraform plan` output showing all new resources
- `terraform apply` success output
- State file showing created resources

### 3. **Verification Script Output**
Create `verify-lab2a.sh`:
```bash
#!/bin/bash
echo "=== Lab 2A Verification ==="
echo "1. Testing direct ALB access (should fail)..."
# ... include all verification commands
echo "2. Testing CloudFront access (should succeed)..."
echo "3. Verifying WAF configuration..."
echo "4. Checking DNS resolution..."
echo "5. Testing secret header requirement..."
```
**Save output as:** `verification-results.txt`

### 4. **Screenshots/Documentation**
- CloudFront distribution configuration
- Route53 record sets pointing to CloudFront
- ALB security group showing prefix list rule
- ALB listener rules showing header validation
- WAF configuration showing CLOUDFRONT scope

### 5. **Incident Response Test**
```bash
# Simulate WAF block
curl -v "https://chewbacca-growl.com/?exec=/bin/bash" 2>&1 | grep -E "HTTP|Blocked"

# Check CloudWatch metrics for WAF
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=WebACL,Value=chewbacca-cf-waf01 \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --period 300 \
  --statistics Sum
```

## Reflection Questions

### 1. **Why must CloudFront certificates be in us-east-1?**
> CloudFront is a global service with its certificate management system located in us-east-1. This design simplifies certificate validation and distribution across all edge locations. While your origin (ALB) can be in any region, the SSL/TLS termination at the edge requires certificates to be managed from us-east-1 for consistency across CloudFront's global network.

### 2. **What's the difference between prefix list restriction and secret header validation?**
> **Prefix List Restriction** is network-level security: only CloudFront's origin-facing IPs can connect to port 443 on the ALB. However, sophisticated attackers could still:
> - Spoof CloudFront IPs (though difficult)
> - Use compromised AWS accounts to create their own CloudFront distributions pointing to your ALB
> 
> **Secret Header Validation** is application-level security: even if someone reaches the ALB, they must provide a secret header value that only your CloudFront distribution knows. This is defense-in-depth—both layers must be compromised for direct access.

### 3. **What are the performance implications of moving WAF to CloudFront?**
> **Advantages:**
> - **Edge enforcement**: Attacks are blocked before reaching your infrastructure, reducing bandwidth and compute costs
> - **Global consistency**: One WAF configuration protects all edge locations
> - **Lower latency**: WAF decisions happen closer to users
> 
> **Considerations:**
> - **CloudFront-scoped WAF** can only protect CloudFront distributions, not other services
> - **Cost structure**: Pay per million requests at edge vs regional
> - **Feature parity**: Some advanced WAF features may differ between scopes

### 4. **How would you handle secret header rotation in production?**
> 1. **Automated rotation**: Use Lambda function triggered by EventBridge to:
>    - Generate new secret
>    - Update CloudFront distribution
>    - Update ALB listener rule
>    - Test connectivity before deleting old rule
> 
> 2. **Blue/Green deployment**: Create new listener rule with new secret, test, then remove old
> 
> 3. **Secrets Manager**: Store header value in Secrets Manager with automatic rotation
> 
> 4. **Monitoring**: CloudWatch alarms for header mismatch errors during rotation

### 5. **What monitoring would you add for this architecture?**
> Critical metrics to monitor:
> - **CloudFront**: 4xx/5xx error rates, cache hit ratio, request counts
> - **WAF**: Blocked request count by rule, allowed request patterns
> - **ALB**: Healthy host count, request count per target
> - **Security**: Unauthorized access attempts (403s on ALB)
> - **DNS**: Resolution success rate, latency
> 
> Key alarms:
> - `CloudFront 5xx rate > 1%`
> - `WAF blocked requests spike > 1000/min`
> - `ALB healthy hosts < 1`
> - `Direct ALB access attempts > 10/min`

## Troubleshooting Guide

### Common Issues and Solutions

| Issue | Symptoms | Solution |
|-------|----------|----------|
| Certificate validation fails | CloudFront distribution fails to deploy | Ensure Route53 validation records exist in us-east-1 |
| 403 from CloudFront | Users get 403 even via CloudFront | Check secret header value matches, ALB listener rule priority |
| ALB still accessible | Direct ALB access returns 200 | Verify prefix list rule replaced 0.0.0.0/0 rule |
| DNS not resolving | Domain points to old ALB IP | Check Route53 alias records point to CloudFront |
| WAF not blocking | Test attacks not blocked | Verify WAF is CLOUDFRONT scope, associated with distribution |

### Debugging Commands
```bash
# Check CloudFront distribution status
aws cloudfront get-distribution --id $CF_ID --query "Distribution.Status"

# Check certificate status
aws acm describe-certificate \
  --certificate-arn $(terraform output -raw cloudfront_cert_arn) \
  --region us-east-1 \
  --query "Certificate.Status"

# Test header flow
curl -v -H "X-Chewbacca-Growl: $SECRET_HEADER" "https://$ALB_DNS" 2>&1 | head -20

# Check ALB access logs (if enabled)
aws s3 ls s3://$(terraform output -raw alb_access_logs_bucket)/

# Verify prefix list
aws ec2 get-managed-prefix-list-entries \
  --prefix-list-id $(aws ec2 describe-managed-prefix-lists \
    --filters "Name=prefix-list-name,Values=com.amazonaws.global.cloudfront.origin-facing" \
    --query "PrefixLists[0].PrefixListId" --output text)
```

---

## Quick Start Commands

```bash
# Initialize and plan
terraform init
terraform plan -out=tfplan-2a

# Apply changes
terraform apply tfplan-2a

# Get outputs
terraform output

# Run verification
./verify-lab2a.sh > verification-results.txt

# Clean up (when done)
terraform destroy -auto-approve
```

**Remember**: Origin cloaking isn't just about security—it's about **architectural discipline**. By making CloudFront the only public ingress, you create a clear security boundary, simplify monitoring, and enable global scalability.
