# EC2 → RDS Integration Lab

Learn how to securely connect an EC2 instance to an RDS MySQL database using AWS best practices. This lab demonstrates a foundational cloud application pattern focused on secure compute-to-database connectivity.

<details>
  <summary>📑 Table of Contents</summary>

- <a href="https://github.com/YOUR_USERNAME/YOUR_REPO/blob/main/README.md#project-overview">Project Overview</a>
- <a href="https://github.com/YOUR_USERNAME/YOUR_REPO/blob/main/README.md#industry-context">Industry Context</a>
- <a href="https://github.com/YOUR_USERNAME/YOUR_REPO/blob/main/README.md#why-this-pattern-matters">Why This Pattern Matters</a>
- <a href="https://github.com/YOUR_USERNAME/YOUR_REPO/blob/main/README.md#architectural-design">Architectural Design</a>
- <a href="https://github.com/YOUR_USERNAME/YOUR_REPO/blob/main/README.md#expected-deliverables">Expected Deliverables</a>
- <a href="https://github.com/YOUR_USERNAME/YOUR_REPO/blob/main/README.md#technical-verification-aws-cli">Technical Verification (AWS CLI)</a>
- <a href="https://github.com/YOUR_USERNAME/YOUR_REPO/blob/main/README.md#common-failure-modes">Common Failure Modes</a>
- <a href="https://github.com/YOUR_USERNAME/YOUR_REPO/blob/main/README.md#conclusion">Conclusion</a>

</details>

## Project Overview

Components:

- **EC2 Instance:** Runs a minimal application.  
- **RDS MySQL Database:** Managed, private, not publicly accessible.  
- **Secure Connectivity:** Configured via VPC and security groups.  
- **Credential Management:** AWS Secrets Manager accessed via IAM role; no hardcoded passwords.  
- **Application Functionality:** Simple app that reads and writes data.

> Focus is on **infrastructure patterns and security**, not the app itself.

**Use cases:** internal enterprise tools, SaaS products, backend APIs, lift-and-shift workloads, cloud security assessments.

## Industry Context

This pattern is commonly tested in interviews. Skills evaluated:

- EC2 → RDS connectivity  
- Database access control  
- Credential management via IAM & Secrets Manager  
- Connectivity verification & debugging  

**Relevant for:** AWS Solutions Architect, Cloud Security, DevOps/SRE roles.

## Why This Pattern Matters

| Skill                     | Importance |
|----------------------------|------------|
| Security Groups            | AWS network boundary; controls access to RDS |
| Least Privilege            | Prevents credential leakage and lateral movement |
| Managed Databases          | Reduces operational responsibility and risk |
| IAM Roles                  | Eliminates static credentials |
| Application-to-DB Trust    | Ensures backend security and controlled access |

## Architectural Design

**Logical Flow:**

[User Browser]  
│  
▼  
[EC2 App]  
│  
▼  
[Secrets Manager]  
│  
▼  
[RDS MySQL]  

- RDS **not public**, only accessible from EC2  
- Credentials via **IAM role**, no hardcoded passwords  

## Expected Deliverables

- **Infrastructure Proof:** EC2 running, RDS in same VPC, security groups, IAM role  
- **Application Proof:** Database initialized, insert/read records  
- **Verification Evidence:** CLI outputs & browser-based data  

## Technical Verification (AWS CLI)

```bash
# EC2 running
aws ec2 describe-instances --filters "Name=tag:Name,Values=lab-ec2-app"

# IAM role attached
aws ec2 describe-instances --instance-ids <INSTANCE_ID> --query "Reservations[].Instances[].IamInstanceProfile.Arn"

# RDS status
aws rds describe-db-instances --db-instance-identifier lab-mysql --query "DBInstances[].DBInstanceStatus"

# RDS endpoint
aws rds describe-db-instances --db-instance-identifier lab-mysql --query "DBInstances[].Endpoint"

# Security group rules
aws ec2 describe-security-groups --group-names sg-rds-lab --query "SecurityGroups[].IpPermissions"

# Secrets Manager access from EC2
aws secretsmanager get-secret-value --secret-id lab/rds/mysql

# MySQL connectivity
mysql -h <RDS_ENDPOINT> -u admin -p

# End-to-end application verification (Browser)
http://<EC2_PUBLIC_IP>/init        # Initialize database
http://<EC2_PUBLIC_IP>/add?note=cloud_labs_are_real   # Add a record
http://<EC2_PUBLIC_IP>/list       # View persisted records
