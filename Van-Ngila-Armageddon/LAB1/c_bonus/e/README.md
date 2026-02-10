# Lab 1C - Bonus E: WAF Logging & Enterprise Incident Correlation

## Overview
This lab extends our observability capabilities by implementing WAF logging with multiple destination options and creating an enterprise-grade incident correlation workflow. We now have complete visibility from the edge (WAF) through the load balancer (ALB) to the application (EC2/RDS), enabling sophisticated incident response.

## Challenges Overcome

### **1. WAF Log Destination Complexity**
- **Problem**: AWS WAFv2 requires specific naming conventions (`aws-waf-logs-` prefix) and supports three different log destinations (CloudWatch, S3, Firehose) with unique configurations for each
- **Solution**: Implemented a toggle-based architecture with Terraform `count` logic allowing students to choose one destination via `waf_log_destination` variable

### **2. Terraform Module Integration Issues**
- **Problem**: WAF resources were deployed in a separate module (`dns`), making logging integration complex due to module boundaries
- **Solution**: Extended the existing `04-waf.tf` in the DNS module with conditional resources, maintaining clean separation while adding logging functionality

### **3. Variable Scope Problems**
- **Problem**: WAF logging variables defined in module but not passed from root module, causing `terraform validate` failures
```hcl
# Error: Reference to undeclared input variable
#   on 01-main.tf line 172, in module "dns":
#  172:   waf_log_retention_days = var.waf_log_retention_days
```
- **Solution**: Added missing variable declarations in root module's `03-variables.tf` and ensured proper variable passing through module hierarchy

### **4. CloudWatch Logs Insights Syntax Complexity**
- **Problem**: Multiple syntax errors in Logs Insights queries due to:
  - Incorrect regex operator usage (`=~` vs `~=`)
  - Unsupported Perl regex flags (`(?i)`)
  - Missing parentheses in complex queries
  - Unsupported `case()` function
- **Solution**: Developed working patterns using:
  - `lower()` function for case-insensitive matching
  - Proper regex escaping for special characters
  - Nested `if()` statements instead of `case()`
  - `parse` command to extract structured fields from log messages

## What We Achieved

### **✅ Three Log Destination Options:**
1. **CloudWatch Logs** (Default) - Fast search and triage with 14-day retention
2. **S3** - Long-term archival for compliance and forensics
3. **Kinesis Firehose** - Real-time streaming to SIEM systems

### **✅ Complete Observability Stack:**
- **WAF Logs**: Edge security events and attack patterns
- **ALB Access Logs**: Traffic patterns and 5xx errors  
- **Application Logs**: Business logic and database errors
- **CloudWatch Metrics**: Aggregated error counts and thresholds

### **✅ Enterprise Incident Correlation:**
Implemented a sophisticated runbook that correlates signals across:
- **Timing**: Aligns WAF blocks with ALB 5xx spikes
- **Patterns**: Distinguishes attacks from backend failures
- **Root Cause**: Classifies errors as secrets drift, network issues, or service failures

## Key Terraform Components

### **Variables Added:**
```hcl
variable "waf_log_destination" {
  description = "Choose ONE destination per WebACL: cloudwatch | s3 | firehose"
  type        = string
  default     = "cloudwatch"
}

variable "waf_log_retention_days" {
  description = "Retention for WAF CloudWatch log group."
  type        = number
  default     = 14
}

variable "enable_waf_sampled_requests_only" {
  description = "If true, filter/redact sensitive fields."
  type        = bool
  default     = false
}
```

### **Conditional Resource Creation:**
```hcl
resource "aws_cloudwatch_log_group" "chewbacca_waf_log_group01" {
  count = var.waf_log_destination == "cloudwatch" ? 1 : 0
  name  = "aws-waf-logs-${var.env_prefix}-webacl01"  # AWS-required prefix
  # ...
}
```

## Critical CloudWatch Logs Insights Queries

### **1. WAF Attack Pattern Detection:**
```sql
fields @timestamp, @message
| filter @message like /BLOCK/
| stats count() as blocks by bin(5m)
| sort @timestamp desc
```

### **2. Application Error Classification:**
```sql
fields @timestamp, @message
| parse @message '* - * - * - *' as timestamp, logger, level, error_message
| filter level = "ERROR"
| stats count() as n by logger, error_message
| sort n desc
```

### **3. Correlation Analysis (Attack vs Backend):**
```sql
-- If BLOCK spikes align with incident time → likely external attack
-- If WAF is quiet but app errors spike → likely backend failure
fields @timestamp, @message
| parse @message '* - * - * - *' as timestamp, logger, level, error_message
| filter error_message =~ /(?i)(access.denied|timeout|refused)/
| stats count() as hits by bin(5m), error_message
| sort @timestamp asc
```

## Career-Critical Skills Developed

### **Incident Triage Capability:**
- **Signal Correlation**: Connect WAF blocks → ALB 5xx → Application errors
- **Root Cause Analysis**: Distinguish between attacks, misconfigurations, and infrastructure failures
- **Recovery Verification**: Validate fixes across the entire stack

### **Observability Architecture:**
- **Multi-Destination Logging**: Choose appropriate storage based on use case (triage vs archive)
- **Cost Optimization**: Balance CloudWatch Logs (search speed) vs S3 (storage cost)
- **Compliance Ready**: Implement log retention and access controls

### **Enterprise Workflow:**
- **Runbook Automation**: Scripted incident investigation with decision trees
- **Metrics-Driven Alerts**: Threshold-based alerting with proper dimensions
- **Cross-Service Debugging**: Trace issues across WAF, ALB, EC2, and RDS

## Why This Matters

This implementation transforms reactive monitoring into proactive incident response:

1. **Before**: "The app is slow" - hours of manual log digging
2. **After**: "WAF blocked 10K attacks at 14:30, causing 5% increase in 5xx errors" - immediate, data-driven insight

The correlation between WAF logs (external threats) and application logs (internal failures) creates a powerful feedback loop for security and reliability improvements.

---

*Author: Vany*  
*AWS Security & Observability Specialist*