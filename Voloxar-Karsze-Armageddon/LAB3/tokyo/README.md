# Armageddon Project - LAB1B: Operations & Incident Response

## 📋 Project Overview
**LAB1B** extends the foundational infrastructure from LAB1A with operational capabilities, observability, and incident response. It demonstrates how to operate, monitor, and recover an EC2-RDS production system using secure secret management and AWS observability tools.

### Primary Objective
Implement a **resilient system** capable of automatically detecting, diagnosing, and recovering from database failures without full redeployment, leveraging **Parameter Store** and **Secrets Manager** for secure configuration storage.

## 🏗️ Architecture & Data Flow
```
[Internet] → [EC2 (Public Subnet)] → [RDS MySQL (Private Subnets)]
                    ↑                         ↑
            [Config Store]           [Secrets Manager]
                    ↓                         ↓
            [Parameter Store]        [IAM Role + Policies]
                    ↳→→→→→→→[CloudWatch Monitoring]→→→[Alarms]→→→[Email/SNS]
```

## ⚙️ Terraform Modules Deployed

| Module | AWS Services | Role in LAB1B |
|--------|--------------|---------------|
| **`network`** | VPC, Subnets, Route Tables, DB Subnet Group | Multi-AZ network isolation |
| **`security`** | Security Groups (EC2 + RDS) | Specific firewall rules |
| **`iam`** | IAM Role, Policies, Instance Profile | Least-privilege permissions with KMS |
| **`ec2`** | EC2 Instance | Application server with IAM profile |
| **`rds`** | RDS MySQL | Non-public Multi-AZ database |
| **`cloudwatch`** | CloudWatch Alarms, Logs, SNS | Monitoring and alerting |
| **`config-store`** | Systems Manager Parameter Store | Centralized configuration storage |

## 🔐 Secret & Configuration Management

### **Dual Secure Storage**
1. **AWS Secrets Manager** (`lab-1b/rds/mysql`) : 
   - Stores RDS credentials (username/password)
   - Dynamic reading via Terraform `data` blocks
   - JSON decoding in `locals.tf`

2. **Systems Manager Parameter Store** (`/lab/db/*`) :
   - Stores configuration (endpoint, port, dbname)
   - Non-sensitive values for quick recovery
   - Integration with `config-store` module

### **Secure Access Flow**
```hcl
# Secure secret reading
data "aws_secretsmanager_secret" "rds" { name = "lab-1b/rds/mysql" }
data "aws_secretsmanager_secret_version" "rds" { secret_id = data.aws_secretsmanager_secret.rds.id }
local.rds_secret = jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)
```

## 🚨 Monitoring & Incident Response

### **Implemented Observability**
- **CloudWatch Logs** : Centralized application logs
- **CloudWatch Alarms** : DB connection failure detection
- **SNS Notifications** : Email alerts for intervention
- **Custom Metrics** : Connection error tracking

### **Recovery Workflow**
1. **Detection** : CloudWatch Alarms triggered
2. **Diagnosis** : CloudWatch Logs consultation
3. **Recovery** : Reading values from Parameter Store/Secrets Manager
4. **Restoration** : Reconfiguration without Terraform redeployment

## 🚀 Deployment

### **Prerequisites**
- Terraform ≥ 1.5.0
- Pre-existing secret in Secrets Manager (`lab-1b/rds/mysql`)
- KMS key for encryption

### **Configuration**
1. Copy the example file:
   ```bash
   cp lab-1b.auto.tfvars.example lab-1b.auto.tfvars
   ```

2. Modify variables in `lab-1b.auto.tfvars`:
   ```hcl
   region = "ap-northeast-1"
   account_id = "YOUR_ACCOUNT_ID"
   kms_key_arn = "YOUR_KMS_KEY_ARN"
   alert_email = "your-email@example.com"
   ```

### **Execution**
```bash
# Initialization
terraform init

# Planning
terraform plan -var-file="lab-1b.auto.tfvars"

# Deployment
terraform apply -var-file="lab-1b.auto.tfvars"
```

## ✅ Required Verifications (LAB1B)

### **Mandatory CLI Checks**
```bash
# 1. Parameter Store
aws ssm get-parameters --names /lab/db/endpoint /lab/db/port /lab/db/name --with-decryption

# 2. Secrets Manager
aws secretsmanager get-secret-value --secret-id lab-1b/rds/mysql

# 3. EC2 Access
# Via SSM Session Manager from the instance

# 4. CloudWatch Logs
aws logs describe-log-groups --log-group-name-prefix /aws/ec2/armageddon-lab-1b

# 5. Alarms
aws cloudwatch describe-alarms --alarm-name-prefix armageddon-db-connection
```

### **Test Scenarios**
1. **Simulate DB failure** : Stop RDS or modify credentials
2. **Verify alerts** : Confirm SNS/email notification
3. **Diagnose via logs** : Identify error in CloudWatch
4. **Recover** : Use Parameter Store/Secrets Manager for reconfiguration

## 📁 File Structure

| File | Description |
|------|-------------|
| **`01-main.tf`** | Main module deployment |
| **`02-locals.tf`** | Local variables and secret decoding |
| **`03-variables.tf`** | Input variables with validation |
| **`04-outputs.tf`** | Terraform outputs |
| **`05-backend.tf`** | S3 backend configuration (commented) |
| **`lab-1b.auto.tfvars.example`** | Configuration example |

## 🎯 Demonstrated Skills

- **Secret Management** : Secure usage of Secrets Manager and Parameter Store
- **Observability** : Monitoring implementation with CloudWatch
- **Resilience** : Design for recovery without redeployment
- **Professional IaC** : Modular and maintainable structure
- **Security** : IAM least-privilege and KMS encryption

## 🔗 Integration with LAB1A and LAB1C

- **LAB1A** : Basic EC2 + RDS infrastructure
- **LAB1B** : ⭐ **Operations & Incident Response** (this lab)
- **LAB1C** : Advanced features (ALB, WAF, VPC Endpoints, Bedrock Automation)

---

**Tags**: `Terraform` `AWS` `Incident-Response` `Secrets-Manager` `Parameter-Store` `CloudWatch` `RDS` `EC2` `Operations` `SRE`