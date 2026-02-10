# **Lab 1C Bonus-B: Enterprise Web Application Infrastructure**

## **Overview**
This lab implements a production-grade web application infrastructure on AWS using Terraform, featuring:
- **Public Application Load Balancer** with TLS termination
- **Private EC2 instances** (no public IPs) for security
- **AWS WAF** protection against web attacks
- **CloudWatch monitoring** with SNS alerts
- **Custom domain** with Route53 DNS and ACM certificates
- **Full infrastructure-as-code** deployment

## **Architecture Diagram**
```
┌─────────────────────────────────────────────────────────────┐
│                    Internet Users                           │
└───────────────────────┬─────────────────────────────────────┘
                        │ HTTPS/443, HTTP/80
                        ▼
┌─────────────────────────────────────────────────────────────┐
│        Application Load Balancer (Public)                   │
│  • TLS Termination with ACM Certificate                     │
│  • WAF Protection (AWS Managed Rules)                       │
│  • HTTP → HTTPS Redirection                                 │
└────────────┬────────────────────────────────────────────────┘
             │ Port 80 (HTTP) to private subnet
             ▼
┌─────────────────────────────────────────────────────────────┐
│          Target Group (EC2 Instances)                       │
│  • Health Checks: /health endpoint                          │
│  • Private subnet placement (no public IPs)                 │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│          EC2 Auto Scaling Group                             │
│  • Amazon Linux 2                                           │
│  • IAM Role with SSM access                                 │
│  • Security groups limiting ingress to ALB only             │
└─────────────────────────────────────────────────────────────┘
```

## **Technical Implementation**

### **Core Components**

1. **Networking Module**
   - VPC with public and private subnets across 2 AZs
   - Route tables and internet gateway
   - ALB in public subnets, EC2 in private subnets
   - Security groups with least-privilege access

2. **ALB Configuration**
   ```terraform
   resource "aws_lb" "alb_public" {
     name               = "${var.env_prefix}-alb-public"
     internal           = false
     load_balancer_type = "application"
     security_groups    = [var.alb_sg_id]
     subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
     enable_deletion_protection = false
   }
   ```

3. **TLS/SSL with ACM**
   - Certificate for `theowafhomework.site` with wildcard `*.theowafhomework.site`
   - DNS validation via Route53 CNAME records
   - HTTPS listener on port 443 with TLS 1.2-1.3 policies

4. **WAF Protection**
   - AWS Managed Rules (Common Rule Set)
   - Regional WAF attached to ALB
   - CloudWatch metrics enabled

5. **Monitoring & Alerting**
   - CloudWatch dashboard for ALB metrics
   - SNS alarm for ALB 5xx errors (>10 in 5 minutes)
   - Email notification integration

## **Critical Learnings & Pitfalls**

### **⚠️ Danger Zone: Certificate Validation**
**Problem**: ACM certificates require DNS validation before ALB can use them
**Solution**: 
```terraform
# WRONG - Will crash ALB creation
certificate_arn = "arn:aws:acm:...certificate/PENDING_VALIDATION"

# CORRECT - Use data source with status filter
data "aws_acm_certificate" "cert" {
  domain   = var.domain_name
  statuses = ["ISSUED"]  # Only validated certificates
}
```

### **⚠️ Danger Zone: Security Group Rules**
**Problem**: Invalid combination of "all protocols" with specific ports
**Solution**:
```terraform
# WRONG - Can't mix -1 (all protocols) with port ranges
resource "aws_vpc_security_group_egress_rule" "bad" {
  ip_protocol = "-1"    # All protocols
  from_port   = 80      # ❌ Invalid with "-1"
  to_port     = 80
}

# CORRECT - Specify protocol and ports separately
resource "aws_vpc_security_group_egress_rule" "good" {
  ip_protocol = "tcp"   # Specific protocol
  from_port   = 80      # ✅ Valid with "tcp"
  to_port     = 80
}
```

### **⚠️ Danger Zone: Terraform Provider Memory**
**Problem**: AWS provider v6.x crashes on Windows with "out of memory"
**Solution**: Pin to stable v5.x
```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.41.0"  # Stable, memory-efficient
    }
  }
}
```

### **⚠️ Danger Zone: Circular Dependencies**
**Problem**: Modules referencing each other creates infinite loops
**Solution**: Unidirectional data flow
```
# WRONG - Circular reference
Module A → depends on → Module B
Module B → depends on → Module A

# CORRECT - Linear flow
DNS Module → outputs cert_arn
     ↓
Network Module → uses cert_arn for ALB
     ↓
EC2 Module → uses ALB DNS name
```

## **Verification Commands**

```bash
# 1. ALB Status
aws elbv2 describe-load-balancers --names ${ENV_PREFIX}-alb-public

# 2. HTTPS Listener
aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN

# 3. Target Health
aws elbv2 describe-target-health --target-group-arn $TG_ARN

# 4. WAF Attachment
aws wafv2 get-web-acl-for-resource --resource-arn $ALB_ARN

# 5. CloudWatch Alarms
aws cloudwatch describe-alarms --alarm-name-prefix ${ENV_PREFIX}-alb-5xx

# 6. Certificate Status
aws acm describe-certificate --certificate-arn $CERT_ARN
```

## **Deployment Workflow**

### **Phase 1: Infrastructure**
```bash
terraform apply -target=module.vpc
terraform apply -target=module.security
```

### **Phase 2: Compute**
```bash
terraform apply -target=module.ec2
terraform apply -target=module.rds
```

### **Phase 3: Load Balancing**
```bash
# Wait for certificate validation first!
terraform apply -target="aws_lb.alb_public"
terraform apply -target="aws_lb_target_group.alb_private_targets"
```

### **Phase 4: Monitoring**
```bash
terraform apply -target=module.cloudwatch
terraform apply -target=module.dns
```

## **Common Issues & Solutions**

| Issue | Symptom | Solution |
|-------|---------|----------|
| Certificate not validated | `UnsupportedCertificate` error | Wait for DNS propagation (5-30 min) |
| Security group error | `InvalidParameterValue` | Separate protocol and port rules |
| Terraform crash | `out of memory` | Use AWS provider v5.x, restart PC |
| Circular dependency | `Cycle` error | Remove module self-references |
| Health check failures | Target `unhealthy` | Check `/health` endpoint on EC2 |

## **Best Practices Implemented**

1. **Security**
   - Private EC2 instances (no public IPs)
   - Least-privilege security groups
   - WAF with managed rules
   - TLS 1.2+ only

2. **Reliability**
   - Multi-AZ deployment
   - ALB health checks
   - Automated monitoring
   - SNS alerts for incidents

3. **Maintainability**
   - Modular Terraform code
   - Consistent naming conventions
   - Environment variables for configuration
   - Comprehensive outputs

4. **Cost Optimization**
   - t3.micro instances for lab
   - No unnecessary resources
   - Cleanup scripts included

## **Cleanup Script**

```bash
#!/bin/bash
# cleanup.sh - Destroy all lab resources
terraform destroy -auto-approve

# Remove local state
rm -rf .terraform
rm -f .terraform.lock.hcl
rm -f terraform.tfstate*

# Optional: Delete Route53 zone manually if needed
# aws route53 delete-hosted-zone --id $ZONE_ID
```

## **Future Enhancements**

1. **Auto Scaling** - Add scaling policies based on CPU/memory
2. **Blue/Green Deployment** - Route53 weighted routing
3. **CI/CD Pipeline** - GitHub Actions for automated deployment
4. **Advanced WAF Rules** - Custom rules for application protection
5. **CloudFront CDN** - Global acceleration and DDoS protection

---

**Lab Status**: ✅ COMPLETED  
**Infrastructure**: Production-ready  
**Key Achievement**: Implemented enterprise patterns with proper security, monitoring, and automation  
**Author**: Vany FERRAND