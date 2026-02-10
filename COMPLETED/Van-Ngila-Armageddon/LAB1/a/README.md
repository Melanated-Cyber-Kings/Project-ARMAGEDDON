# Armageddon Project - LAB1A: Foundational Infrastructure with Secure Secrets Management

## 📋 Project Overview
**LAB1A** establishes the foundational cloud infrastructure for a secure, scalable web application using Infrastructure as Code (IaC) principles. This lab demonstrates secure deployment patterns with Terraform, implementing a modular architecture that separates compute and data layers while maintaining security best practices.

### Primary Objective
Deploy a **secure web application (EC2)** that connects to a **managed database (RDS MySQL)** using credentials retrieved from **AWS Secrets Manager** instead of hardcoded values, establishing a production-ready IaC foundation.

## 🏗️ Architecture & Security Flow
```
[Internet]
    ↓ (HTTP/SSH via Security Groups)
[EC2 Instance (Public Subnet)]
    ↓ (MySQL 3306 - Security Group Rules)
[RDS MySQL (Multi-AZ, Private Subnets)]
    ↑
[AWS Secrets Manager] ←(IAM Role/Policies)← [EC2 Instance Profile]
```
**Core Security Principle**: No credentials in Terraform code; all secrets dynamically retrieved from AWS Secrets Manager at deployment time.

## ⚙️ Terraform Modules Deployed

| Module | AWS Services | Purpose |
|--------|--------------|---------|
| **`network`** | VPC, Public/Private Subnets (2 AZs), Route Tables, Internet Gateway, DB Subnet Group | Network isolation with public/private separation |
| **`security`** | Security Groups for EC2 (HTTP/SSH inbound) and RDS (MySQL from EC2 only) | Least-privilege firewall rules |
| **`iam`** | IAM Role, Policies, Instance Profile with KMS decryption permissions | Secure access to Secrets Manager |
| **`ec2`** | EC2 Instance (t3.micro) with attached IAM profile | Application server in public subnet |
| **`rds`** | RDS MySQL (db.t3.micro, Multi-AZ enabled) | Managed database in private subnets |

## 🔐 Secure Secrets Management Implementation

### **Dynamic Secret Retrieval**
```hcl
# 1. Reference existing secret (does NOT create it)
data "aws_secretsmanager_secret" "rds" {
  name = "lab-1a/rds/mysql"
}

# 2. Get current secret version
data "aws_secretsmanager_secret_version" "rds" {
  secret_id = data.aws_secretsmanager_secret.rds.id
}

# 3. Decode JSON into Terraform object
locals {
  rds_secret = jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)
}

# 4. Use in RDS module (no hardcoded credentials)
module "rds" {
  db_username = local.rds_secret.username
  db_password = local.rds_secret.password
  db_name     = local.rds_secret.dbname
}
```

### **IAM Security Configuration**
- **EC2 IAM Role**: `armageddon-lab-1a-ec2-secrets-role`
- **Attached Policies**: 
  - Custom policy: `armageddon-lab-1a-EC2ReadRDSSecret`
  - Permissions: `secretsmanager:GetSecretValue`, `secretsmanager:DescribeSecret`
  - KMS: `kms:Decrypt` for secret encryption key
- **Resource Scoping**: Restricted to specific secret ARN

## 🛡️ Security Validation (From Provided Files)

### **Verified Security Groups**
```json
EC2 Security Group (sg-0e6822d557178b340):
- Inbound: HTTP (80) from 0.0.0.0/0, SSH (22) from 0.0.0.0/0
- Outbound: All traffic to 0.0.0.0/0
- Tags: Name = "sg-ec2-armageddon-lab-1a"

RDS Security Group (sg-0a917dbff4a70ffdd):
- Inbound: MySQL (3306) ONLY from EC2 Security Group
- Outbound: All traffic to 0.0.0.0/0
- Tags: Name = "armageddon-lab-1a-rds-sg"
```

### **Verified RDS Configuration**
- **Instance**: `lab-mysql` (MySQL 8.0.43, db.t3.micro)
- **Multi-AZ**: Enabled (Primary: ap-northeast-1c, Secondary: ap-northeast-1a)
- **Public Access**: `false` (properly isolated in private subnets)
- **Subnets**: Private subnets across 2 AZs
- **Security**: Single VPC security group with EC2-only access

### **Verified Secrets Manager**
- **Secret**: `lab-1a/rds/mysql` (rotation enabled)
- **Structure**: JSON with `username`, `password`, `host`, `port`, `dbname`
- **Rotation**: Configured with Lambda function `rotation`

## 🚀 Deployment Process

### **Prerequisites**
- Pre-existing secret in AWS Secrets Manager (`lab-1a/rds/mysql`)
- KMS key for encryption
- Terraform ≥ 1.5.0

### **Configuration**
1. Copy example variables file:
   ```bash
   cp lab-1a.auto.tfvars.example lab-1a.auto.tfvars
   ```

2. Update `lab-1a.auto.tfvars`:
   ```hcl
   region = "ap-northeast-1"
   account_id = "031857855861"
   kms_key_arn = "arn:aws:kms:ap-northeast-1:031857855861:key/0987dcba-09fe-87dc-65ba-ab0987654321"
   # Other variables as needed
   ```

### **Execution**
```bash
# Initialize Terraform
terraform init

# Review deployment plan
terraform plan -var-file="lab-1a.auto.tfvars"

# Apply infrastructure
terraform apply -var-file="lab-1a.auto.tfvars"
```

## ✅ Infrastructure Validation Commands

### **Core AWS CLI Verification**
```bash
# 1. Verify Security Groups
aws ec2 describe-security-groups \
  --group-ids sg-0e6822d557178b340 sg-0a917dbff4a70ffdd \
  --region ap-northeast-1

# 2. Verify RDS Configuration
aws rds describe-db-instances \
  --db-instance-identifier lab-mysql \
  --region ap-northeast-1 \
  --query 'DBInstances[0].{PubliclyAccessible:PubliclyAccessible,MultiAZ:MultiAZ,VpcSecurityGroups:VpcSecurityGroups}'

# 3. Verify Secrets Manager
aws secretsmanager describe-secret \
  --secret-id lab-1a/rds/mysql \
  --region ap-northeast-1

# 4. Verify IAM Role Configuration
aws iam list-attached-role-policies \
  --role-name armageddon-lab-1a-ec2-secrets-role

# 5. Verify EC2-IAM Integration
aws ec2 describe-instances \
  --instance-ids i-038c0094823165402 \
  --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn'
```

### **Network Verification**
```bash
# Verify RDS is NOT publicly accessible
aws rds describe-db-instances \
  --db-instance-identifier lab-mysql \
  --query 'DBInstances[0].PubliclyAccessible' \
  --output text
# Should return: False

# Verify RDS subnet placement
aws rds describe-db-subnet-groups \
  --db-subnet-group-name armageddon-lab-1a-db-subnet-group \
  --query 'DBSubnetGroups[0].Subnets[].SubnetIdentifier'
```

## 📁 Project Structure

| File | Purpose |
|------|---------|
| **`01-main.tf`** | Main module orchestration and secret data sources |
| **`02-locals.tf`** | Local variables and secret JSON decoding |
| **`03-variables.tf`** | Input variables with environment validation |
| **`04-outputs.tf`** | Terraform outputs (VPC, subnet IDs, RDS endpoint) |
| **`05-backend.tf`** | S3 backend configuration (commented) |
| **`lab-1a.auto.tfvars.example`** | Example configuration values |
| **`Armageddon-lab1a-Van.txt`** | Comprehensive validation commands and outputs |

## 🔄 Secrets Rotation Setup

### **Separate Rotation Infrastructure**
```hcl
# In separate Terraform configuration
resource "aws_secretsmanager_secret_rotation" "rds_rotation" {
  secret_id           = aws_secretsmanager_secret.rds_secret.id
  rotation_lambda_arn = "arn:aws:lambda:ap-northeast-1:031857855861:function:rotation"
  
  rotation_rules {
    automatically_after_days = 30
  }
}
```

### **Rotation Verification**
```bash
# Confirm rotation is enabled
aws secretsmanager describe-secret \
  --secret-id lab-1a/rds/mysql \
  --query 'RotationEnabled'
# Should return: true
```

## 🎯 Key Design Principles Demonstrated

1. **Security First**: No hardcoded credentials; all secrets from Secrets Manager
2. **Least Privilege**: IAM roles scoped to specific secrets; security groups with minimal rules
3. **High Availability**: Multi-AZ RDS deployment; subnets across multiple AZs
4. **Network Isolation**: Public EC2, private RDS, security group rules for controlled access
5. **Infrastructure as Code**: Modular Terraform design for maintainability
6. **Operational Excellence**: Comprehensive validation commands for all components

## 🏆 Success Metrics

- ✅ EC2 instance running with correct IAM profile
- ✅ RDS MySQL instance in private subnets (Multi-AZ enabled)
- ✅ Security groups allowing only necessary traffic
- ✅ Secrets Manager integration working (EC2 can read secrets)
- ✅ No credentials in Terraform state or code
- ✅ RDS not publicly accessible
- ✅ Secrets rotation configured

---

**Tags**: `Terraform` `AWS` `Secrets-Manager` `RDS` `EC2` `Security-Groups` `IAM` `Infrastructure-as-Code` `Multi-AZ` `MySQL`

## 🔗 Next Steps (LAB1B)
This foundation enables **LAB1B** which adds operational capabilities:
- Parameter Store for configuration
- CloudWatch logging and alarms
- Incident response procedures
- Automated recovery workflows