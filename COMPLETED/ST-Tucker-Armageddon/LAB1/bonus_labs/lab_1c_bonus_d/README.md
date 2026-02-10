# Lab-1C — Bonus D  
## Route53 Apex ALIAS & ALB Access Logging (S3)

## Overview

Bonus D increases production realism for Lab-1C by implementing:

1. **Route53 apex ALIAS record → ALB**
2. **ALB access logs → S3**
3. **CLI validation** proving DNS, logging attributes, traffic flow, and S3 delivery

---

## Repository Locations

### Ingress module (Bonus D changes)

```
modules/ingress/
├── alb.tf
├── alb_access_logs.tf
├── route53.tf
├── outputs.tf
└── variables.tf
```

### Environment wiring

```
envs/lab-1c/
├── 03-variables.tf
└── 04-outputs.tf
```

### Deliverables

```
deliverables/
├── bonus_d_cli_verification.md
└── bonus_d_validation.md
```

---

## Deployment Workflow (CRITICAL)

Lab‑1C uses Secrets Manager and optional rotation.  
To avoid dependency loops, the workflow is:

1) Deploy `secrets/` **without rotation Lambda ARN**  
2) Deploy `envs/lab-1c/`  
3) Update `secrets/` with real DB host  
4) **Enable rotation by uncommenting Lambda ARN**  
5) During teardown, **comment the Lambda ARN again before destroy**

---

## ⚠️ IMPORTANT — Lambda ARN Toggle Discipline

Rotation Lambdas create CloudFormation stacks that frequently block destroy operations if left attached.

### During first secrets deploy:

In `secrets/terraform.tfvars`:

```
# rotation_lambda_arn = ""
# rotation_days       = 30
```

Leave them commented.

---

### After environment is deployed:

Populate:

```
rotation_lambda_arn = "arn:aws:lambda:REGION:ACCOUNT:function:lab-1c-rds-rotation"
rotation_days       = 30
```

Re‑apply secrets.

---

### BEFORE teardown:

**Comment these back out**:

```
# rotation_lambda_arn = "arn:aws:lambda:REGION:ACCOUNT:function:lab-1c-rds-rotation"
# rotation_days       = 30
```

Then:

```
terraform apply
```

Only after that:

```
cd envs/lab-1c
terraform destroy
```

---

## 1️⃣ Configure Secrets Backend (Placeholder DB Host)

```bash
cd secrets
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars

terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

---

## 2️⃣ Deploy Lab‑1C Environment

```bash
cd ../envs/lab-1c
cp backend.hcl.example backend.hcl

terraform init -reconfigure -backend-config=backend.hcl
terraform plan -var-file=lab-1c.auto.tfvars
terraform apply -var-file=lab-1c.auto.tfvars
```

---

## 3️⃣ Update Secrets with Real Database Host

```bash
cd ../../secrets
terraform -chdir=../envs/lab-1c output -raw rds_address
```

Edit tfvars and re‑apply.

---

## 4️⃣ Enable Secret Rotation (Optional)

Locate Lambda:

```bash
aws lambda list-functions   --region ap-northeast-1   --query "Functions[?contains(FunctionName,'lab-1c') && contains(FunctionName,'rotation')].[FunctionName,FunctionArn]"   --output table
```

Update tfvars → apply.

---

## Bonus D Validation

### Verify ALB logging:

```bash
aws elbv2 describe-load-balancer-attributes   --load-balancer-arn $(terraform output -raw alb_arn)
```

### Generate traffic:

```bash
APP=$(terraform output -raw app_fqdn)
APEX=$(terraform output -raw apex_fqdn)

for i in {1..40}; do
  curl -I https://$APP || true
  curl -I https://$APEX || true
done
```

### Verify logs:

```bash
aws s3 ls s3://$(terraform output -raw alb_logs_bucket_name)/$(terraform output -raw alb_access_logs_prefix)/AWSLogs/$(aws sts get-caller-identity --query Account --output text)/elasticloadbalancing/ --recursive | head
```

---

## Completion Criteria

- apex ALIAS exists
- ALB logging enabled
- logs in S3
- deliverables captured
- Lambda ARN toggled correctly before destroy
