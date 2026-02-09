# Lab 1C — Bonus C  
## Operational DNS & TLS Automation

---

## 📋 Lab Overview

Bonus‑C extends Lab‑1C and Bonus‑B by introducing **production‑grade DNS
management** and **fully automated TLS certificate issuance** using:

- Amazon Route53  
- AWS Certificate Manager (ACM)  
- Application Load Balancer (ALB)  
- AWS WAFv2  

> **NOTE:** You must own and control a public domain name.  
> A Route53 hosted zone must be created and delegated at your registrar.

Public access to the application is strictly:

- DNS → ALB  
- HTTPS termination at the ALB  
- WAF inspection  

---

## 🎯 Learning Objectives

This lab exercises the ability to:

- Implement Route53 ALIAS records
- Automate ACM DNS validation
- Eliminate manual TLS workflows
- Enforce deterministic Terraform destroys
- Troubleshoot DNS leftovers
- Capture operational evidence
- Generate audit‑ready CLI artifacts

---

## 🧭 Position in the Course

| Stage   | Focus |
|--------|------|
| Lab‑1A | EC2 → RDS foundation |
| Lab‑1B | Logging and alerts |
| Lab‑1C | Failure simulation |
| Bonus‑A | Private networking hardening |
| Bonus‑B | Public ingress + WAF |
| **Bonus‑C** | **DNS + TLS automation** |

---

## 🏗️ Architecture Summary

- Custom VPC  
- Public ALB subnets  
- Private EC2  
- Private RDS  
- Secrets Manager + rotation Lambda  
- SSM Parameter Store  
- CloudWatch + SNS  
- AWS WAF  
- Route53 hosted zone  
- ACM DNS‑validated certificate  

---

## 📁 Repository Layout

```
lab_1c_bonus_c/
├── bootstrap/
├── secrets/
├── envs/lab-1c/
├── modules/
├── deliverables/
│   └── bonus_c_cli_verification.md
└── README.md
```

---

# 🚀 Deployment Workflow (MANDATORY tfvars + backend.hcl)

Terraform must always be executed with the correct:

- backend.hcl
- tfvars file

Secrets uses:

```
terraform.tfvars
```

Environment uses:

```
lab-1c.auto.tfvars
```

Failure to do so can cause:

- orphaned Route53 records  
- stuck ACM certificates  
- broken HTTPS listeners  
- failed destroy operations  

---

# ⚠️ IMPORTANT — Lambda ARN Toggle Discipline

Secrets rotation Lambdas can block teardown operations.

### During FIRST secrets deploy:

In `secrets/terraform.tfvars`:

```
# rotation_lambda_arn = ""
# rotation_days       = 30
```

Leave commented.

---

### After environment is deployed:

Populate:

```
rotation_lambda_arn = "arn:aws:lambda:REGION:ACCOUNT:function:lab-1c-rds-rotation"
rotation_days       = 30
```

Re‑apply secrets.

---

### BEFORE destroy:

Comment these again:

```
# rotation_lambda_arn = "arn:aws:lambda:REGION:ACCOUNT:function:lab-1c-rds-rotation"
# rotation_days       = 30
```

Apply:

```
terraform apply
```

Only then proceed with environment destroy.

---

# 1️⃣ Deploy Secrets First

```
cd secrets

cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars

terraform init -backend-config=backend.hcl
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

---

# 2️⃣ Deploy Environment Stack

```
cd ../envs/lab-1c

cp backend.hcl.example backend.hcl

terraform init  -reconfigure -backend-config=backend.hcl
terraform plan  -var-file=lab-1c.auto.tfvars
terraform apply -var-file=lab-1c.auto.tfvars
```

---

# 🧹 Destroy Workflow (CRITICAL)

Before destroying:

1) Disable rotation Lambda in secrets  
2) Apply secrets  
3) Destroy environment  

```
cd secrets
terraform apply -var-file=terraform.tfvars

cd ../envs/lab-1c
terraform destroy -var-file=lab-1c.auto.tfvars
```

Never destroy without explicit tfvars.

---

# 🧪 Validation and Evidence

Run:

```
envs/lab-1c/scripts/bonus_c_validate.sh
```

Artifact produced:

```
deliverables/bonus_c_cli_verification.md
```

---

## 📁 Required Deliverables

- terraform_plan.txt  
- terraform_apply.txt  
- terraform_destroy.txt  
- bonus_c_cli_verification.md  

---

# 🔎 DNS Cleanup Verification (Post‑Destroy)

After destroy:

```
aws route53 list-resource-record-sets   --hosted-zone-id <ZONE_ID>
```

Expected only:

- NS  
- SOA  

---

# 🚨 Issues Encountered

### 🔧 Destroy Left DNS Records

**Cause:** Destroy without tfvars.

**Fix:**

```
terraform destroy -var-file=lab-1c.auto.tfvars
```

---

### 🔧 ACM Stuck in PENDING_VALIDATION

**Cause:** Delegation missing or CNAME absent.

**Fix:**

- verify registrar NS
- re‑apply Terraform

---

### 🔧 HTTPS Listener Failed

**Cause:** Listener created before cert issuance.

**Fix:** Add dependency on:

```
aws_acm_certificate_validation.app_cert
```

---

### 🔧 Route53 Re‑Apply Failed

**Cause:** Existing records conflicted.

**Fix:**

```
allow_overwrite = true
```

---

# 🧹 Teardown Checklist

- [ ] terraform destroy succeeded  
- [ ] ALBs gone  
- [ ] ACM certs gone  
- [ ] Route53 only NS/SOA  
- [ ] No WAF ACLs  

---

# 🎓 Operational Lessons

- DNS must be IaC‑controlled  
- TLS automation removes human bottlenecks  
- Destroy hygiene matters  
- Validation artifacts are audit‑critical  
- Rotation Lambdas require discipline
