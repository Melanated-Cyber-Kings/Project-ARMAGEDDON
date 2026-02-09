# LAB1A — Armageddon Project  
## Foundational AWS Infrastructure with Secure Secrets Management (Terraform)

> **Primary workflow:** Terraform CLI  
> **Optional accelerator:** Makefile

---

## Overview

LAB1A builds the core AWS infrastructure for a production‑style workload using Terraform and secure secret handling.

This lab provisions:

- VPC networking (public + private subnets, routing, IGW, DB subnet group)
- Public EC2 instance (application host)
- Private RDS MySQL database
- AWS Secrets Manager secret used by EC2 at runtime
- Two security groups (EC2 + RDS) with least‑privilege rules

---

## Architecture

```
[Internet]
   |
   |  HTTP (80) + SSH (22 from your IP only)
   v
[EC2 — Public Subnet]
   |
   |  MySQL (3306 from EC2 SG only)
   v
[RDS — Private Subnets]
   ^
   |
[AWS Secrets Manager]
```

---

# Required Workflow — Terraform CLI

Terraform is run only from:

✅ `bootstrap/secrets`  
✅ `bootstrap/state` (optional)  
✅ `envs/lab-1a`  

❌ Never run Terraform inside `modules/`.

---

## Step 0 — Preflight

```
terraform -v
aws sts get-caller-identity
```

---

## Step 1 — Secure SSH Access (Required)

SSH must be restricted **before** any infrastructure is created.

Determine your public IP:

```
curl https://checkip.amazonaws.com
```

Edit `envs/lab-1a/lab-1a.auto.tfvars`:

```
ssh_ingress_cidr = "<YOUR_IP>/32"
key_name         = "lab1a-user"
```

This ensures port 22 is only accessible from your workstation.

---

## Step 2 — Bootstrap Secrets

```
cd bootstrap/secrets
cp terraform.tfvars.example terraform.tfvars

terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

---

## Step 3 — Deploy Environment

```
cd ../../envs/lab-1a
cp lab-1a.auto.tfvars.example lab-1a.auto.tfvars

terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

---

## Step 4 — Update Secret with Live RDS Endpoint

```
RDS_ENDPOINT="$(aws rds describe-db-instances \
  --region ap-northeast-1 \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)"

aws secretsmanager put-secret-value \
  --region ap-northeast-1 \
  --secret-id lab-1a/rds/mysql \
  --secret-string "{\"username\":\"admin\",\"password\":\"<PASSWORD>\",\"host\":\"$RDS_ENDPOINT\",\"address\":\"$RDS_ENDPOINT\",\"port\":3306,\"dbname\":\"labdb\"}"
```

---

## Step 5 — Validate Deployment

### Infrastructure

```
aws ec2 describe-instances --filters Name=tag:Lab,Values=LAB1A Name=instance-state-name,Values=running \
  --query 'Reservations[].Instances[].{ID:InstanceId,PublicIP:PublicIpAddress}' --output table

aws rds describe-db-instances \
  --query 'DBInstances[].{ID:DBInstanceIdentifier,Public:PubliclyAccessible,MultiAZ:MultiAZ,Endpoint:Endpoint.Address}' \
  --output table
```

### Application

After retrieving the EC2 public IP, access:

```
http://<EC2_PUBLIC_IP>/
```

Then run:

```
# Initialize schema (run once)
curl http://<EC2_PUBLIC_IP>/init

# Insert a record
curl "http://<EC2_PUBLIC_IP>/add?note=lab1a"

# List records
curl "http://<EC2_PUBLIC_IP>/list"
```

---

## Step 6 — Teardown

```
cd envs/lab-1a
terraform destroy
```

---

# Optional Workflow — Makefile Automation

The Makefile runs the same Terraform commands from the project root.

```
make preflight
make bootstrap-secrets
make plan
make apply
make update-secret-host
make verify
make destroy
```

---

## Completion Checklist

- [ ] Secrets created or updated
- [ ] VPC, EC2, and RDS deployed
- [ ] SSH restricted to your IP
- [ ] Application reachable
- [ ] RDS not public
- [ ] Teardown successful

---

## Next Lab

LAB1B adds:

- Parameter Store
- CloudWatch logs
- Alarms
- SNS notifications
