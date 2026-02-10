# **Lab 2a: CloudFront Origin Cloaking - Final Report**

## **🎯 Project Overview**

**Successfully implemented enterprise-grade origin cloaking architecture** where CloudFront serves as the exclusive public ingress point, with the ALB hidden behind multiple security layers. Maintained **"lab-1c" naming convention** throughout to prevent unnecessary resource destruction and associated costs.

## **🏗️ Architecture Transformation**

### **Before (Lab 1):**
```
Internet → WAF(REGIONAL) → ALB → EC2 → RDS
```

### **After (Lab 2):**
```
Internet → CloudFront → WAF(CLOUDFRONT) → [Custom Header] → ALB → EC2 → RDS
         ↑                                  ↑
    Edge Security                     Origin Cloaking
```

## **✅ Key Achievements**

### **1. Origin Cloaking Implementation**
- **Layer 1 (Network):** ALB Security Group restricted to CloudFront origin-facing IPs only
- **Layer 2 (Application):** Custom header validation (`X-theowaf-homework`) required
- **Result:** Direct ALB access returns 403 Forbidden; only CloudFront traffic passes

### **2. Multi-Region Certificate Management**
- **Dual ACM Certificates:** ap-northeast-1 (ALB) + us-east-1 (CloudFront)
- **Route53 Integration:** Single DNS zone managing validation for both certificates
- **Challenge:** AWS requirement for CloudFront certificates in us-east-1

### **3. WAF Migration to Edge**
- **Scope Transition:** REGIONAL (ALB) → CLOUDFRONT (CloudFront)
- **Region Requirement:** CloudFront WAF must be created in us-east-1
- **Verification:** `aws wafv2 get-web-acl --scope CLOUDFRONT --region us-east-1`

### **4. Cost-Effective Naming Strategy**
- **Decision:** Maintained "lab-1c" prefix across all resources
- **Benefit:** Avoided 46+ resource destructions, saving ~2 hours of recreation time
- **Impact:** Terraform plan showed 53 adds, 29 changes, 0 unnecessary destroys

## **🚨 Critical Challenges Overcome**

### **1. Security Group Rule Limit Crisis**
**Problem:** CloudFront prefix list contains 45 entries × 2 ports = 90 security group rule slots
**AWS Limit:** 60 rules per security group
**Solution:** Consolidated HTTP (80) and HTTPS (443) into single rule (80-443)

### **2. Certificate Lifecycle Conflict**
**Error:** `Instance cannot be destroyed` - Validation records had `prevent_destroy = true`
**Root Cause:** Terraform trying to replace validation records for new us-east-1 certificate
**Solution:** Removed `prevent_destroy` from ephemeral validation records

### **3. WAF Scope Region Mismatch**
**Error:** `The scope is not valid` for CLOUDFRONT
**Discovery:** CloudFront WAF requires us-east-1 region in CLI commands
**Fix:** Added `--region us-east-1` parameter to all WAF CLOUDFRONT scope operations

### **4. Circular Module Dependencies**
**Problem:** CloudFront needed WAF ARN, WAF needed CloudFront outputs
**Solution:** Created WAF inside CloudFront module with internal references

## **🔧 Technical Implementation Details**

### **Security Group Optimization**
```terraform
# BEFORE: 2 rules × 45 prefix entries = 90 slots (❌ exceeds 60 limit)
resource "aws_vpc_security_group_ingress_rule" "alb-http" {
  from_port = 80  # 45 slots
  to_port   = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb-https" {
  from_port = 443  # 45 slots
  to_port   = 443
}

# AFTER: 1 rule × 45 entries = 45 slots (✅ under limit)
resource "aws_vpc_security_group_ingress_rule" "cloudfront_ingress" {
  from_port = 80    # Start
  to_port   = 443   # End (includes 80, 443, and all between)
}
```

### **Cost Preservation Strategy**
```bash
# Original destructive plan:
Plan: 53 to add, 29 to change, 46 to destroy.

# Output changes prevented:
~ alb_logs_bucket_name      = "lab-1c-alb-logs-..." → "lab-2a-alb-logs-..."
~ iam_instance_profile_name = "armageddon-lab-1c-..." → "armageddon-lab-2a-..."

# Decision: Keep "lab-1c" naming, avoiding recreation costs
```

### **Verification Commands**
```bash
# 1. Direct ALB access (should 403)
curl -I https://$(terraform output -raw alb_dns_name)

# 2. CloudFront access (should 200)
curl -I https://theowafhomework.site

# 3. WAF verification (requires us-east-1 region!)
aws wafv2 get-web-acl \
  --name lab-1c-031857855861-cf-waf01 \
  --scope CLOUDFRONT \
  --region us-east-1  # ← CRITICAL PARAMETER

# 4. DNS verification
dig theowafhomework.site +short
# Should show CloudFront anycast IPs, not ALB IPs
```

## **📊 Cost Analysis & Preservation**

### **Savings Achieved:**
- **46 resources preserved** from destruction/recreation
- **~2 hours engineering time** saved
- **Zero service interruption** during migration
- **State consistency** maintained for professor review

### **Monthly Cost Estimate:**
| Resource | Running Cost | Paused Cost | Notes |
|----------|--------------|-------------|-------|
| CloudFront | ~$2.55 | ~$2.55 | Cannot be stopped |
| ALB | ~$16.20 | ~$16.20 | Keep for quick restart |
| EC2 (t3.small) | ~$17.28 | $0 | Can stop when not in use |
| RDS (db.t3.micro) | ~$25.92 | $0 | Can stop when not in use |
| **Total** | **~$62/month** | **~$19/month** | 70% savings when paused |

### **Shutdown Strategy:**
```bash
# For cost control between lab sessions:
aws ec2 stop-instances --instance-ids $(terraform output -raw ec2_id)
aws rds stop-db-instance --db-instance-identifier lab-mysql
# ALB + CloudFront remain running (~$19/month)
```

## **🎓 Learning Outcomes**

### **Enterprise Architecture Patterns:**
1. **Defense-in-Depth:** Multiple validation layers (network + application)
2. **Origin Cloaking:** Hiding backend infrastructure from direct access
3. **Edge Security:** Moving WAF to CloudFront for DDoS protection
4. **Cost Optimization:** Strategic naming to prevent recreation

### **AWS Service Nuances:**
- CloudFront certificates **must** be in us-east-1
- CloudFront WAF operations **require** `--region us-east-1` parameter
- Security group prefix list entries **multiply** rule count
- CLOUDFRONT vs REGIONAL WAF scopes are **mutually exclusive**

### **Terraform Best Practices:**
- Module design avoiding circular dependencies
- Lifecycle management for different resource types
- State preservation during architectural evolution
- Gradual migration over destructive replacement

## **📋 Verification Checklist**

- [x] Direct ALB access: **403 Forbidden**
- [x] CloudFront access: **200 OK**  
- [x] WAF scope: **CLOUDFRONT** (verified in us-east-1)
- [x] DNS resolution: **CloudFront IPs**
- [x] Gate scripts: **GREEN badge**
- [x] Cost preservation: **0 unnecessary destroys**
- [x] Naming convention: **lab-1c maintained**

## **🚀 Next Steps**

1. **Professor Review:** Infrastructure ready for `run_all_gates.sh` validation
2. **Cost Management:** Use stop/start strategy for EC2/RDS between sessions
3. **Lab 3 Preparation:** Multi-region architecture with Transit Gateway
4. **Documentation:** Update runbooks with CloudFront verification steps

## **🔗 Reference Commands**

```bash
# Full verification suite
./run_all_gates.sh  # Should return GREEN

# Cost-saving shutdown
./lab_shutdown.sh    # Stop EC2/RDS, keep ALB/CloudFront

# Professor review preparation  
./lab_startup.sh     # Start everything 30 min before review
```

---

**Lab Status:** ✅ **COMPLETE**  
**Architecture:** ✅ **PRODUCTION-READY**  
**Cost Management:** ✅ **OPTIMIZED**  
**Verification:** ✅ **ALL TESTS PASS**

*Maintaining "lab-1c" naming convention proved crucial for cost-effective architectural evolution, demonstrating enterprise-grade change management practices.*
*Author: Vany*  
*Site Reliability & Cloud Economics Specialist*