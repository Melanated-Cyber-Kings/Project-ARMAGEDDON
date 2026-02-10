# LAB-1B --- Terraform: Monitoring, Alerts, and Incident Simulation (EC2 → RDS)

## Purpose

LAB-1B extends the baseline EC2 → RDS environment by adding operational
monitoring and incident alerting.

This lab focuses on:

-   shipping application logs from EC2 to CloudWatch Logs
-   converting a log pattern into a CloudWatch metric
-   alarming on real service symptoms (DB connection failures)
-   notifying responders via SNS
-   validating incident response through controlled failure injection
    and recovery

LAB-1A establishes the foundational infrastructure patterns (VPC, EC2,
RDS, Secrets, networking).\
LAB-1B builds the operational layer on top of that baseline.

------------------------------------------------------------------------

## What LAB-1B Deploys / Configures

Infrastructure and operations components:

-   CloudWatch log group for app logs (`/aws/ec2/lab-rds-app`)
-   CloudWatch Agent configured on EC2 (via user-data) to ship
    `/var/log/rdsapp.log`
-   Metric filter on the log group matching `DB_CONNECTION_ERROR`
-   Custom metric emitted per error event (for example:
    `DBConnectionErrors` in `Lab/RDSApp`)
-   CloudWatch Alarm triggering when **≥ 3 errors in 5 minutes**
-   SNS topic + email subscription for notifications
-   Incident simulation runbooks and validation steps

------------------------------------------------------------------------

## Repository Layout (Relevant Paths)

-   `bootstrap/` --- Terraform backend bootstrap
-   `secrets/` --- Secrets Manager and Parameter Store values
-   `envs/lab-1b/` --- LAB-1B environment
-   `modules/` --- reusable Terraform modules

------------------------------------------------------------------------

## Prerequisites

-   AWS CLI configured
-   Terraform installed
-   SNS-capable email address available
-   SSH key pair (if EC2 access is required)
-   Region assumed to be `ap-northeast-1` unless overridden

Recommended environment variables:

```
export AWS_PROFILE="your-profile"
export AWS_REGION="ap-northeast-1"
```

------------------------------------------------------------------------

# Deployment Instructions --- Bootstrap → Secrets → envs/lab-1b

LAB-1B must be deployed in stages:

1.  **bootstrap/** --- backend + IAM + rotation Lambda
2.  **secrets/** --- placeholder secrets, later updated
3.  **envs/lab-1b/** --- full infrastructure
4.  **secrets/** --- update with real DB endpoint
5.  *(Optional)* enable rotation

All commands assume execution from the repository root.

------------------------------------------------------------------------

## 1️⃣ Bootstrap Backend & IAM

Change into the bootstrap directory:

```
cd LAB1/b/bootstrap
```

Copy variables:

```
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to match your environment.

Initialize and deploy:

```
terraform init
terraform plan
terraform apply
```

Record:

-   S3 bucket name
-   DynamoDB table name

------------------------------------------------------------------------

## 2️⃣ Configure Secrets Backend (Placeholder DB Host)

```
cd LAB1/b/secrets

cp backend.hcl.example backend.hcl
```

Edit `backend.hcl` with backend values.

Copy tfvars:

```
cp terraform.tfvars.example terraform.tfvars
```

Deploy:

```
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

------------------------------------------------------------------------

## 3️⃣ Deploy LAB-1B Environment

```
cd LAB1/b/envs/lab-1b

cp backend.hcl.example backend.hcl
```

Deploy:

```
terraform init -reconfigure -backend-config=backend.hcl
terraform plan -var-file=lab-1b.auto.tfvars
terraform apply -var-file=lab-1b.auto.tfvars
```

------------------------------------------------------------------------

## 4️⃣ Update Secrets with Real Database Host

```
cd LAB1/b/secrets
```

Edit `terraform.tfvars` and replace the placeholder hostname.

Re-apply:

```
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

------------------------------------------------------------------------

## 5️⃣ Optional --- Enable Secret Rotation

Edit `terraform.tfvars`:

-   set `rotation_lambda_arn`
-   set `rotation_days`

Find Lambda ARN:

```
aws lambda list-functions   --region ap-northeast-1   --query "Functions[?contains(FunctionName,'lab-1b') && contains(FunctionName,'rotation')].[FunctionName,FunctionArn]"   --output table
```

Re-apply:

```
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Validate:

```
aws secretsmanager describe-secret   --secret-id lab-1b/rds/mysql   --query '{RotationEnabled:RotationEnabled,RotationLambdaARN:RotationLambdaARN}'   --output json
```

------------------------------------------------------------------------

# Post-Deploy Validation

## Confirm CloudWatch Agent

```
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
```

------------------------------------------------------------------------

## Incident Simulation

Break RDS access by modifying the inbound SG rule for port 3306.

Generate errors:

```
for i in {1..8}; do
  curl -s "http://<EC2_PUBLIC_IP>/list" >/dev/null
  sleep 10
done
```

Check alarm:

```
aws cloudwatch describe-alarms   --region ap-northeast-1   --alarm-names "lab-db-connection-failure"   --query 'MetricAlarms[0].StateValue'   --output text
```

------------------------------------------------------------------------

# Access EC2 via Session Manager

```
aws ssm start-session   --target <INSTANCE_ID>   --region ap-northeast-1
```

------------------------------------------------------------------------

# Notes for Users

-   Do not skip stages.
-   Avoid console edits unless instructed.
-   Destroy environments in reverse order.
-   Rotation is optional unless required.
-   Terraform state is part of the lab artifact.
