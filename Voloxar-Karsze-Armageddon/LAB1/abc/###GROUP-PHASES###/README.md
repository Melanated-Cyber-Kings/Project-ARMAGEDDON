<h1 align="center">ARMAGEDDON PROJECT LAB 1a</h1>


<br>

**Project Co-ordinator:** 
<a href="https://github.com/BalericaAI">THEO WAF CEO</a>

<br>

**Project Leader:** 
<a href="https://github.com/Charles-Roro">Charles CEO</a>

<br>

**Project Group Leader:** 
<a href="https://github.com/Brimah-Khalil-Kamara">Brimah Khalil Kamara</a>

<br>

**Cloud Engineers (Infrastructure & Networking):**

<a href="https://github.com/BashiM1">Mahamed Bashir</a> , <a href="https://github.com/statuc30721">ST Tucker</a> , <a href="https://github.com/Futurist2099">Trevore Jerome (F-2099)</a> , <a href="https://github.com/jareonbailey-web">Jae Bailey</a> and <a href="https://github.com/twixxxman357">Alastair Davis</a>

<br>




**DevSecOps (Identity, Secrets, Least Privilege):**

<a href="https://github.com/anthonyadeconsulting-source">Adeji Adeyei</a> , <a href="https://github.com/theswordpt-git">Voloxar Karsze</a> , <a href="https://github.com/Lew228">Shawn Mosby</a> , 
<a href="https://github.com/Cameron-Cleveland">Cameron-Cleveland</a> and <a href="https://github.com/penorpencil44">Mark Thornhill</a>


<br>

**Dev Tooling:**

<a href="https://github.com/waseeconsulting-git">Van Ngila</a> , <a href="https://github.com/DBs-art">Daniel Bryce</a> , <a href="https://github.com/BennyCampCloud">Campanella Godfrey Jr</a> and <a href="https://github.com/AnunnakiRa">Anunnaki MetuNetter AmenRa</a> 


<br>


---

<br>









# EC2 → RDS Integration LAB 1a

Learn how to securely connect an **EC2 instance** to an **RDS MySQL database** using AWS best practices. This lab demonstrates a foundational cloud application pattern focused on **secure compute-to-database connectivity**.

<details>
  <summary>📑 Table of Contents</summary>

1. [Project Overview](#project-overview)  
2. [Industry Context](#industry-context)  
3. [Why This Pattern Matters](#why-this-pattern-matters)  
4. [Architectural Design](#architectural-design)  
5. [Expected Deliverables](#5-expected-deliverables)  
6. [Technical Verification (AWS CLI)](#6-technical-verification-aws-cli)  
7. [Common Failure Modes](#common-failure-modes)  
8. [Conclusion](#conclusion)  

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

## 5. Expected Deliverables

- **Infrastructure Proof:** EC2 running, RDS in same VPC, security groups, IAM role  
- **Application Proof:** Database initialized, insert/read records  
- **Verification Evidence:** CLI outputs & browser-based data  

## 6. Technical Verification (AWS CLI)

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

```

## Common Failure Modes


| Failure                 | Lesson |
|-------------------------|--------|
| Connection timeout      | Security group or network routing issue |
| Access denied           | IAM or Secrets Manager misconfiguration |
| App starts but DB fails | Dependency order or initialization issue |
| Works once then breaks  | Stateless compute vs stateful database behavior |


## Conclusion

Completing this lab demonstrates the ability to:

- Securely connect EC2 → RDS  
- Use IAM roles and Secrets Manager correctly  
- Verify and troubleshoot AWS infrastructure  
- Understand real-world AWS application security patterns

> “I understand how real AWS applications securely connect compute to managed databases.”
