# Lab 1C - Bonus C: Route53 & ACM DNS Validation

## 🎯 **Objective**
Implement production-grade DNS management with automated TLS certificate validation using Route53 and ACM.

## 📁 **Project Structure**
```
modules/dns/
├── 01-dns.tf           # Route53 zone, ACM cert, DNS records
├── 02-variables.tf     # Module inputs
├── 03-outputs.tf       # Module outputs
└── 04-waf.tf          # WAF configuration (separate)
```

## 🔧 **Implementation**

### **Core Components:**
1. **Route53 Hosted Zone** - DNS authority for your domain
2. **ACM Certificate** - TLS certificate with wildcard (`*.domain.com`)
3. **DNS Validation Records** - CNAME records to prove domain ownership
4. **ALIAS Record** - `app.domain.com` → Application Load Balancer

### **Key Terraform Resources:**
```hcl
# Route53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = var.domain_name
}

# ACM Certificate (DNS validation)
resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  subject_alternative_names = ["*.${var.domain_name}"]
}

# DNS Validation Records (automated)
resource "aws_route53_record" "cert_validation" {
  for_each = {for dvo in aws_acm_certificate.cert.domain_validation_options : 
              dvo.domain_name => dvo}
  # Creates CNAME records for ACM validation
}

# ALIAS Record to ALB
resource "aws_route53_record" "app_alias" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.${var.domain_name}"
  type    = "A"
  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
```

## 🚨 **Challenges Faced & Solutions**

### **Challenge 1: Certificate Validation Timeouts**
**Problem:** ACM certificate validation timed out after 45 minutes waiting for DNS propagation.

**Solution:**
- Added `lifecycle.prevent_destroy = true` to validation records
- Used `timeouts { create = "45m" }` in validation resource
- Manual DNS record verification before Terraform apply

### **Challenge 2: Mixed Resource/Data Source Issues**
**Problem:** Switching between `resource "aws_acm_certificate"` and `data "aws_acm_certificate"` caused destruction plans.

**Solution:**
- Stuck with **resource** approach with `ignore_changes` lifecycle:
```hcl
lifecycle {
  ignore_changes = [
    domain_validation_options,
    status,
    validation_method
  ]
  prevent_destroy = true
}
```

### **Challenge 3: Missing Wildcard Validation Record**
**Problem:** Only 2 of 3 required CNAME validation records were created.

**Root Cause:** Wildcard (`*.domain.com`) validation record had same value as root domain but wasn't created.

**Solution:**
- Verified all Subject Alternative Names in certificate
- Manually created missing CNAME record in Route53
- Added validation record count check in outputs

### **Challenge 4: Module Dependencies**
**Problem:** ALB HTTPS listener needed certificate validation complete.

**Solution:**
- Removed `depends_on` (certificate already ISSUED)
- Used certificate ARN directly in listener:
```hcl
certificate_arn = module.dns.acm_certificate_arn
```

## ✅ **Verification Steps**

```bash
# 1. Check DNS resolution
dig app.theowafhomework.site +short

# 2. Verify certificate status
aws acm describe-certificate \
  --certificate-arn $(terraform output -module=dns acm_certificate_arn) \
  --query "Certificate.Status"

# 3. Test HTTPS endpoint
curl -I https://app.theowafhomework.site

# 4. Check Route53 records
aws route53 list-resource-record-sets \
  --hosted-zone-id $(terraform output -module=dns route53_zone_id) \
  --query "ResourceRecordSets[?Type=='CNAME']"
```

## 🛡️ **Best Practices Implemented**

1. **Idempotent Infrastructure:** `ignore_changes` prevents unnecessary modifications
2. **Destruction Protection:** `prevent_destroy` on critical resources
3. **Modular Design:** Separated DNS logic into reusable module
4. **Validation Automation:** DNS validation records created automatically
5. **Health Checking:** `evaluate_target_health = true` on ALIAS records

## ⚠️ **Common Pitfalls to Avoid**

1. **Don't delete validation CNAME records** - Certificate will become invalid
2. **Check all Subject Alternative Names** - Ensure wildcard and subdomains included
3. **Wait for DNS propagation** - Can take 5-10 minutes
4. **Use consistent providers** - ACM in Tokyo region for ALB
5. **Monitor certificate expiry** - ACM auto-renews but good to monitor

## 📈 **Outcome**
- ✅ Production-ready DNS management
- ✅ Automated TLS certificate validation
- ✅ HTTPS endpoint accessible at `https://app.your-domain.com`
- ✅ Infrastructure-as-Code for DNS records
- ✅ Wildcard certificate for future subdomains

## 🚀 **Next Steps (Bonus D)**
1. Add apex domain record (`domain.com` → ALB)
2. Implement ALB access logging to S3
3. Create S3 bucket with proper lifecycle policies
4. Add CloudWatch metrics for log analysis

---

**Time to Complete:** 3-4 hours (including debugging)  
**Key Learning:** DNS validation automation, Terraform lifecycle management, ACM-Route53 integration  
**Author**: Vany
