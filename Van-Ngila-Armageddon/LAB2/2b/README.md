**LAB 2B: CLOUDFRONT CACHE CORRECTNESS IMPLEMENTATION**
**Project Overview**
This lab implements enterprise-grade CloudFront cache policies to separate static content (aggressively cached) from API endpoints (never cached), following AWS best practices for performance and security.

**Objectives**
✅ Implement Cache Policies: Separate policies for static vs API content

✅ Origin Request Policies: Forward only necessary headers to origin

✅ Response Headers Policy: Explicit cache control for static content

✅ CloudFront Behavior Updates: Apply policies via ordered cache behaviors

✅ Validation: Prove correctness through HTTP headers and cache behavior

**Architecture Diagram**
text
Client → CloudFront (Edge) → WAF → [X-theowaf-homework] → ALB → EC2 (Flask) → RDS
           ├─ /static/* (Aggressive Cache: 1 day TTL)
           └─ /api/* (No Cache: TTL=0)
**Technical Implementation**
**1. Cache Policies**
Static Content (shinjuku_cache_static01)
terraform
default_ttl = 86400        # 1 day aggressive caching
parameters_in_cache_key_and_forwarded_to_origin {
  cookies_config { cookie_behavior = "none" }
  query_strings_config { query_string_behavior = "none" }
  headers_config { header_behavior = "none" }  # Maximize cache hits
}
API Endpoints (shinjuku_cache_api_disabled01)
terraform
default_ttl = 0            # Disable caching
parameters_in_cache_key_and_forwarded_to_origin {
  cookies_config { cookie_behavior = "none" }
  query_strings_config { query_string_behavior = "none" }
  headers_config { header_behavior = "none" }
}
**2. Origin Request Policies**
Static Content (shinjuku_orp_static01)
terraform
headers_config {
  header_behavior = "whitelist"
  headers { items = ["X-theowaf-homework", "Host"] }  # Critical: Host header!
}
API Endpoints (shinjuku_orp_api01)
terraform
headers_config {
  header_behavior = "whitelist"
  headers { items = ["Authorization", "Content-Type", "Origin", "Host"] }
}
**3. Response Headers Policy**
terraform
custom_headers_config {
  items {
    header   = "Cache-Control"
    override = true
    value    = "public, max-age=86400, immutable"
  }
}
**4. CloudFront Distribution Update**
terraform
# Default behavior (API-safe)
default_cache_behavior {
  cache_policy_id          = aws_cloudfront_cache_policy.shinjuku_cache_api_disabled01.id
  origin_request_policy_id = aws_cloudfront_origin_request_policy.shinjuku_orp_api01.id
}

# Ordered behavior for static content
ordered_cache_behavior {
  path_pattern           = "/static/*"
  cache_policy_id            = aws_cloudfront_cache_policy.shinjuku_cache_static01.id
  origin_request_policy_id   = aws_cloudfront_origin_request_policy.shinjuku_orp_static01.id
  response_headers_policy_id = aws_cloudfront_response_headers_policy.shinjuku_rsp_static01.id
}
**Key Learnings**
**Cache Key Design Principles**
Static Content: No cookies/headers/query strings = maximum cache hits

API Endpoints: Disable caching entirely = prevent security incidents

Cache Isolation: Different query strings create separate cache entries

**Origin Forwarding Strategy**
Forward what origin needs, not everything

Critical Headers: Host header is REQUIRED for proper routing

Security Headers: Authorization for API authentication

Origin Cloaking: X-theowaf-homework for ALB security

**Common Mistakes & Solutions**
**Mistake 1: Missing Host Header in Static Policy**
Symptom: 502 Bad Gateway for /static/* but other endpoints work
Root Cause: Flask needs Host header for routing
Solution: Add "Host" to whitelist in static origin request policy

**Mistake 2: Security Group Rule Limit**
Symptom: RulesPerSecurityGroupLimitExceeded error
Root Cause: CloudFront prefix list contains 45 CIDRs → 90+ rules
Solution: Use single rule with port range (80-443) instead of separate rules

**Mistake 3: Flask Static File Serving Conflict**
Symptom: 502 errors despite correct CloudFront configuration
Root Cause: Flask static_folder conflicts with custom route handlers
Solution: Choose one approach:

Option A: Use Flask's static serving + actual files on disk

Option B: Custom route handler without static_folder

**Mistake 4: Cache Policy Misconfiguration**
Symptom: API responses cached, causing security issues
Root Cause: default_ttl > 0 for API cache policy
Solution: Set default_ttl = 0, max_ttl = 0, min_ttl = 0 for API policies

**Validation Tests**
Gate Script (gate_cache_correctness.sh)
bash
#!/bin/bash
# Tests:
# 1. Static content shows Age > 0 and X-Cache: Hit after first request
# 2. API endpoints show Age: 0 and X-Cache: Miss always
# 3. Different query strings create separate cache entries
# 4. Auth headers are forwarded to API but not cached
Manual Verification
bash
# Static content caching
curl -I https://your-domain.com/static/test.txt
# Expected: Cache-Control: public, max-age=86400, immutable
#           X-Cache: Hit from CloudFront (after first request)

# API non-caching
curl -I https://your-domain.com/api/health
# Expected: X-Cache: Miss from CloudFront (always)

# Auth header forwarding
curl -H "Authorization: Bearer token123" https://your-domain.com/api/data
# Expected: JSON response showing auth header was received
Performance Impact
Static Cache Hit Rate: ~90% expected

Origin Load Reduction: ~90% for static traffic

API Security: 0% caching prevents user data mixups

Security Implications
No API Caching: Prevents user A seeing user B's data

Origin Cloaking: ALB only accepts CloudFront traffic

Header Validation: Only whitelisted headers reach origin

TLS Enforcement: CloudFront → ALB uses HTTPS only

Production Recommendations
Monitoring: CloudWatch metrics for cache hit ratio

Invalidation: Cache invalidation strategy for static updates

WAF Integration: Edge security with managed rule sets

Logging: Enable CloudFront access logs for audit trail

Terraform State Management

# Safe apply sequence
terraform apply -target=aws_cloudfront_cache_policy
terraform apply -target=aws_cloudfront_origin_request_policy
terraform plan -target=module.cloudfront.aws_cloudfront_distribution
terraform apply -target=module.cloudfront.aws_cloudfront_distribution

**Troubleshooting Guide**

Symptom	Possible Cause	Solution
502 Bad Gateway	Missing Host header	Add "Host" to origin request policy
API responses cached	Cache policy TTL > 0	Set default_ttl = 0 for API policy
Static not caching	Response missing Cache-Control	Add response headers policy
CloudFront update fails	Invalid policy combination	Verify headers/cookies/query config

**Conclusion**
Lab 2B transforms CloudFront from a simple CDN to an intelligent caching layer that:

Optimizes performance through aggressive static caching

Ensures security by preventing API response caching

Maintains correctness through proper cache key design

Provides auditability via HTTP header validation

The implementation follows AWS best practices and mirrors real-world production configurations where cache misconfiguration is a leading cause of outages and security incidents.

**Author:** Vany FERRAND
**Date:** February 2026
Status: ✅ COMPLETE