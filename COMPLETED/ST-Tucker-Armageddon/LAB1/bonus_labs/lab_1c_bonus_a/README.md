# Lab 1C — Bonus A
## Private EC2 Operations with SSM, VPC Endpoints, and Secrets Rotation

---

## 📋 Overview

Bonus‑A extends **Lab‑1C** by shifting the operating posture from
*build and recover* to **production‑style hardening**.

The same core services remain:

- EC2 application host
- RDS MySQL
- Secrets Manager with rotation
- SSM Parameter Store
- CloudWatch Logs and alarms
- SNS notifications
- Custom VPC with NAT

Bonus‑A focuses on:

> Operating private compute securely and validating runtime access paths
> through AWS control planes.

---

## 🎯 Objectives

By completing this bonus, you will:

- Operate EC2 exclusively in private subnets
- Remove inbound SSH
- Use Session Manager for access
- Deploy VPC Interface Endpoints
- Continue Secrets Manager rotation
- Validate runtime access to configuration stores
- Produce audit‑style evidence artifacts
- Practice safe teardown procedures

---

## 🏗️ Architecture (Modified from Lab‑1C)

- Custom VPC
- NAT Gateway
- EC2 app host in private subnet
- Private RDS instance
- Secrets Manager + rotation Lambda
- SSM Parameter Store
- CloudWatch Logs + alarms
- SNS topic
- VPC Interface Endpoints:
  - SSM
  - EC2Messages
  - SSMMessages
  - CloudWatch Logs
  - Secrets Manager
  - (optional) KMS
- S3 Gateway Endpoint

---

## 📁 Repository Layout

```
lab_1c_bonus_a/
├── bootstrap/
├── secrets/
├── envs/lab-1c/
├── modules/
├── deliverables/
└── README.md
```

---

# 🚀 Deployment Process (Local State Only)

This bonus lab uses **local Terraform state**.

Remote S3 backends are **not used**.

If any backend is configured in a directory, disable it before running:

```
terraform init -backend=false
```

---

# 🔁 Two‑Pass Secrets Rotation Flow

Secrets rotation requires the Lambda ARN created in the environment
stack. Deployment therefore happens in **two passes**.

---

## Step 1 — Prepare Secrets tfvars (Rotation Disabled)

Edit:

```
secrets/terraform.tfvars
```

Ensure the rotation ARN line is commented:

```
# rotation_lambda_arn = "arn:aws:lambda:REGION:ACCOUNT:function:NAME"
```

---

## Step 2 — Deploy Secrets (Base Secret Only)

```
cd secrets
terraform init -backend=false
terraform validate
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

If the secret already exists:

```
ARN="$(aws secretsmanager describe-secret   --secret-id lab-1c/rds/mysql   --region ap-northeast-1   --query ARN --output text)"

terraform import aws_secretsmanager_secret.rds_secret "$ARN"
terraform apply -var-file=terraform.tfvars
```

---

## Step 3 — Deploy Environment (Bonus‑A)

```
cd ../envs/lab-1c
terraform init -backend=false
terraform validate
terraform plan  -var-file=lab-1c.auto.tfvars
terraform apply -var-file=lab-1c.auto.tfvars
```

---

## Step 4 — Capture Rotation Lambda ARN

```
terraform output
terraform output -raw rotation_lambda_arn
```

---

## Step 5 — Re‑Enable Rotation and Re‑Apply Secrets

Edit:

```
secrets/terraform.tfvars
```

Paste:

```
rotation_lambda_arn = "arn:aws:lambda:REGION:ACCOUNT:function:NAME"
```

Then:

```
cd ../../secrets
terraform validate
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

---

# 🧪 Validation and Evidence

All runtime checks and CLI output must be recorded in:

```
deliverables/bonus_a_cli_verification.md
```

---

## ✅ Completion Checklist

- terraform apply succeeds in both stacks
- EC2 has no public IP
- SSH removed
- SSM login works
- parameters readable
- secrets readable
- VPC endpoints exist
- terraform destroy completes cleanly

---

# 🧹 Teardown and Cleanup (Important)

Destroy resources in **reverse dependency order**.

---

## Step 1 — Detach Rotation (prevents Lambda teardown failures)

Comment the ARN again:

```
# rotation_lambda_arn = "arn:aws:lambda:REGION:ACCOUNT:function:NAME"
```

Then re‑apply secrets:

```
cd secrets
terraform apply -var-file=terraform.tfvars
```

(Optional verify):

```
aws secretsmanager describe-secret   --secret-id "lab-1c/rds/mysql"   --region ap-northeast-1   --query '{Name:Name,RotationEnabled:RotationEnabled,RotationLambdaARN:RotationLambdaARN}'   --output table
```

---

## Step 2 — Destroy Environment

```
cd ../envs/lab-1c
terraform destroy -var-file=lab-1c.auto.tfvars
```

---

## Step 3 — Destroy Secrets

```
cd ../../secrets
terraform destroy -var-file=terraform.tfvars
```

---

## ⏳ Lambda Slow Delete Notes

Secrets rotation uses a Lambda deployed through CloudFormation.

During teardown, Terraform may appear to stall for **10–20 minutes**.
AWS is removing:

- CloudFormation stack resources
- Lambda permissions
- CloudWatch log groups
- Network interfaces (ENIs)
- Secrets Manager rotation bindings

This behavior is expected.

---

## 🚨 Troubleshooting Slow or Stuck Destroy

### CloudFormation — list relevant stacks

```
aws cloudformation list-stacks --region ap-northeast-1   --stack-status-filter DELETE_IN_PROGRESS DELETE_FAILED   --query "StackSummaries[?contains(StackName, 'rotation') || contains(StackName, 'lab-1c')].[StackName,StackStatus]"   --output table
```

### CloudFormation — inspect recent events

```
aws cloudformation describe-stack-events --region ap-northeast-1   --stack-name <STACK_NAME>   --query "StackEvents[0:25].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId,ResourceStatusReason]"   --output table
```

### Lambda VPC ENIs

```
aws ec2 describe-network-interfaces --region ap-northeast-1   --filters Name=description,Values="AWS Lambda VPC ENI*"   --query "NetworkInterfaces[].{Id:NetworkInterfaceId,Status:Status,Subnet:SubnetId,Groups:Groups[].GroupId}"   --output table
```

### Lambda Log Groups

```
aws logs describe-log-groups --region ap-northeast-1   --log-group-name-prefix "/aws/lambda/"   --query "logGroups[?contains(logGroupName, 'rotation') || contains(logGroupName, 'lab-1c')].[logGroupName,retentionInDays]"   --output table
```

---

## ✅ Teardown Complete When

- terraform destroy finishes in both directories
- No CloudFormation stacks remain
- Secret rotation is disabled or destroyed
- No lab Lambdas remain
