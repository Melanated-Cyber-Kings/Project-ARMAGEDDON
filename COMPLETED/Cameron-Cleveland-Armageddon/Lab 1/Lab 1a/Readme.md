# EC2 → RDS Integration Lab
## Foundational Cloud Application Pattern

## Table of Contents
- [Project Overview](#project-overview)
- [Why This Lab Exists](#why-this-lab-exists)
- [Why This Pattern Matters](#why-this-pattern-matters)
- [Architectural Design](#architectural-design)
- [Expected Deliverables](#expected-deliverables)
- [Technical Verification](#technical-verification-using-aws-cli)
- [Common Failure Modes](#common-failure-modes)
- [What This Lab Proves](#what-this-lab-proves-about-you)
- [Lab Implementation Guide](#lab-implementation-guide)
- [Student Deliverables](#student-deliverables)

## Project Overview

In this lab, you will build a classic cloud application architecture:
- **Compute Layer**: Running on an Amazon EC2 instance
- **Data Layer**: Managed relational database hosted on Amazon RDS (MySQL)
- **Secure Connectivity**: Using VPC networking and security groups
- **Credential Management**: Using AWS Secrets Manager
- **Application**: Simple Flask web app that writes and reads data from the database

**Note**: The application itself is intentionally minimal. The learning value is not the app, but the cloud infrastructure pattern it demonstrates.

### Real-World Applications
This pattern appears in:
- Internal enterprise tools
- SaaS products
- Backend APIs
- Legacy modernization projects
- Lift-and-shift workloads
- Cloud security assessments

**If you can build and verify this pattern, you understand the foundation of real AWS workloads.**

## Why This Lab Exists

### Industry Context
This is one of the most common interview architectures. Employers routinely expect engineers to understand:
- How EC2 communicates with RDS
- How database access is restricted
- Where credentials are stored
- How connectivity is validated
- How failures are debugged

You will encounter variations of this question in:
- AWS Solutions Architect interviews
- Cloud Security roles
- DevOps and SRE interviews
- Incident response scenarios

**If you cannot explain this pattern clearly, you will struggle in real cloud environments.**

## Why This Pattern Matters

### What Employers Are Actually Testing
This lab evaluates whether you understand:

| Skill | Why It Matters |
|-------|---------------|
| Security Groups | Primary AWS network security boundary |
| Least Privilege | Prevents credential leakage & lateral movement |
| Managed Databases | Operational responsibility vs infrastructure |
| IAM Roles | Eliminates static credentials |
| Application-to-DB Trust | Core of backend security |

**This is not a toy problem. This is how real systems are built.**

## Architectural Design

### Logical Flow
1. A user sends an HTTP request to an EC2 instance
2. The EC2 application:
   - Retrieves database credentials from Secrets Manager
   - Connects to the RDS MySQL endpoint
3. Data is written to or read from the database
4. Results are returned to the user

### Security Model
- RDS is **not publicly accessible**
- RDS only allows inbound traffic from the EC2 security group
- EC2 retrieves credentials dynamically via IAM role
- No passwords are stored in code or AMIs

**This is intentional friction — security is part of the design.**

## Expected Deliverables

Each student must submit:

### A. Infrastructure Proof
1. EC2 instance running and reachable over HTTP
2. RDS MySQL instance in the same VPC
3. Security group rule showing:
   - RDS inbound TCP 3306
   - Source = EC2 security group (not 0.0.0.0/0)
4. IAM role attached to EC2 allowing Secrets Manager access

### B. Application Proof
1. Successful database initialization
2. Ability to insert records into RDS
3. Ability to read records from RDS

### C. Verification Evidence
1. CLI output proving connectivity and configuration
2. Browser output showing database data

## Technical Verification Using AWS CLI

You are expected to prove your work using the CLI — not screenshots alone.

### 6.1 Verify EC2 Instance
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=lab-ec2-app" \
  --query "Reservations[].Instances[].InstanceId"
```
**Expected**: Instance ID returned, Instance state = running

### 6.2 Verify IAM Role Attached to EC2
```bash
aws ec2 describe-instances \
  --instance-ids <INSTANCE_ID> \
  --query "Reservations[].Instances[].IamInstanceProfile.Arn"
```
**Expected**: ARN of an IAM instance profile (not null)

### 6.3 Verify RDS Instance State
```bash
aws rds describe-db-instances \
  --db-instance-identifier lab-mysql \
  --query "DBInstances[].DBInstanceStatus"
```
**Expected**: `Available`

### 6.4 Verify RDS Endpoint (Connectivity Target)
```bash
aws rds describe-db-instances \
  --db-instance-identifier lab-mysql \
  --query "DBInstances[].Endpoint"
```
**Expected**: Endpoint address, Port 3306

### 6.5 Verify Security Group Rules (Critical)
**RDS Security Group Inbound Rules**
```bash
aws ec2 describe-security-groups \
  --group-names sg-rds-lab \
  --query "SecurityGroups[].IpPermissions"
```
**Expected**: TCP port 3306, Source referencing EC2 security group ID, not CIDR

### 6.6 Verify Secrets Manager Access (From EC2)
SSH into EC2 and run:
```bash
aws secretsmanager get-secret-value \
  --secret-id lab/rds/mysql
```
**Expected**: JSON containing: username, password, host, port

### 6.7 Verify Database Connectivity (From EC2)
Install MySQL client (temporary validation):
```bash
sudo dnf install -y mysql
```
Connect:
```bash
mysql -h <RDS_ENDPOINT> -u admin -p
```
**Expected**: Successful login, No timeout or connection refused errors

### 6.8 Verify Data Path End-to-End
From browser:
- `http://<EC2_PUBLIC_IP>/init`
- `http://<EC2_PUBLIC_IP>/add?note=cloud_labs_are_real`
- `http://<EC2_PUBLIC_IP>/list`

**Expected**: Notes persist across refresh, Data survives application restart

## Common Failure Modes

| Failure | Lesson |
|---------|--------|
| Connection timeout | Security group or routing issue |
| Access denied | IAM or Secrets Manager misconfiguration |
| App starts but DB fails | Dependency order matters |
| Works once then breaks | Stateless compute vs stateful DB |

**Every failure here mirrors real production outages.**

## What This Lab Proves About You

If you complete this lab correctly, you can say:

**"I understand how real AWS applications securely connect compute to managed databases."**

That is a non-trivial claim in the job market.

## Lab Implementation Guide

### EC2 Web App → RDS (MySQL) "Notes" App

**Goal**: Deploy a simple web app on an EC2 instance that can:
- Insert a note into RDS MySQL
- List notes from the database

**Requirements**:
- RDS MySQL instance in a private subnet
- EC2 instance running a Python Flask app
- Security groups allowing EC2 → RDS on port 3306
- Credentials stored in AWS Secrets Manager

### Part 1 — Create RDS MySQL
**Option A (recommended)**: RDS private + EC2 public

**RDS Console → Create database**:
- Engine: MySQL
- Template: Free tier (or Dev/Test)
- DB instance identifier: `lab-mysql`
- Master username: `admin`
- Password: generate or set (keep it safe)
- Connectivity:
  - VPC: default (or class VPC)
  - Public access: **No**
  - VPC security group: create new `sg-rds-lab`

**Security group for RDS (`sg-rds-lab`)**: Allow DB access only from the app server's SG
- **Inbound**: MySQL/Aurora (TCP 3306) Source = `sg-ec2-lab`
- **Outbound**: default allow-all

### Part 2 — Launch EC2
1. EC2 Console → Launch instance
2. Name: `lab-ec2-app`
3. AMI: Amazon Linux 2023
4. Instance type: t3.micro (or t2.micro)
5. Key pair: choose/create (only if you want SSH access)
6. Network: same VPC as RDS
7. Security group: create `sg-ec2-lab`

**Security group for EC2 (`sg-ec2-lab`)**:
- **Inbound**:
  - HTTP TCP 80 from `0.0.0.0/0`
  - (Optional) SSH TCP 22 from your IP only
- **Outbound**: allow-all (default)

**Now go back to RDS SG inbound rule**: Set Source = `sg-ec2-lab` for TCP 3306.

### Part 3 — Store DB Creds (Secrets Manager)
1. Secrets Manager → Store a new secret
2. Secret type: Credentials for RDS database
3. Username/password: admin + your password
4. Select your RDS instance `lab-mysql`
5. Secret name: `lab/rds/mysql`

**Create an IAM Role for EC2 to read the secret**:
1. IAM → Roles → Create role
2. Trusted entity: EC2
3. Add permission policy (recommended inline policy):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:<REGION>:<ACCOUNT_ID>:secret:lab/rds/mysql*"
    }
  ]
}
```
4. Attach role to EC2: EC2 → Instance → Actions → Security → Modify IAM role → select your role

### Part 4 — Bootstrap the EC2 App (User Data)
In EC2 launch, paste this in User data:

```bash
#!/bin/bash
# Update system
sudo dnf update -y

# Install dependencies
sudo dnf install -y python3 python3-pip git

# Clone or create app
cd /home/ec2-user
git clone <YOUR_REPO> || mkdir app && cd app

# Create Flask app (app.py)
cat > app.py << 'EOF'
from flask import Flask, request, jsonify
import pymysql
import boto3
import json
import os

app = Flask(__name__)

def get_db_config():
    client = boto3.client('secretsmanager', region_name='us-east-1')
    response = client.get_secret_value(SecretId='lab/rds/mysql')
    secret = json.loads(response['SecretString'])
    return secret

def get_db_connection():
    config = get_db_config()
    return pymysql.connect(
        host=config['host'],
        user=config['username'],
        password=config['password'],
        database='notesdb',
        cursorclass=pymysql.cursors.DictCursor
    )

@app.route('/init')
def init_db():
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("CREATE DATABASE IF NOT EXISTS notesdb")
            cursor.execute("USE notesdb")
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS notes (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    note TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
        conn.commit()
        conn.close()
        return "Database initialized successfully", 200
    except Exception as e:
        return f"Error: {str(e)}", 500

@app.route('/add')
def add_note():
    note = request.args.get('note', '')
    if not note:
        return "Missing 'note' parameter", 400
    
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("INSERT INTO notes (note) VALUES (%s)", (note,))
        conn.commit()
        conn.close()
        return f"Note added: {note}", 200
    except Exception as e:
        return f"Error: {str(e)}", 500

@app.route('/list')
def list_notes():
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM notes ORDER BY created_at DESC")
            notes = cursor.fetchall()
        conn.close()
        return jsonify(notes), 200
    except Exception as e:
        return f"Error: {str(e)}", 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
EOF

# Install Python packages
pip3 install flask pymysql boto3

# Run the app
nohup python3 app.py > /var/log/app.log 2>&1 &
```

### Part 5 — Test
1. In RDS console, copy the endpoint
2. Open browser:
   - `http://<EC2_PUBLIC_IP>/init`
   - `http://<EC2_PUBLIC_IP>/add?note=first_note`
   - `http://<EC2_PUBLIC_IP>/list`

**Troubleshooting**: If `/init` hangs or errors, check:
- RDS SG inbound not allowing from EC2 SG on 3306
- RDS not in same VPC/subnets routing-wise
- EC2 role missing `secretsmanager:GetSecretValue`
- Secret doesn't contain host/username/password fields

## Student Deliverables

### 1) Screenshots of:
- RDS SG inbound rule using source = `sg-ec2-lab`
- EC2 role attached
- `/list` output showing at least 3 notes

### 2) Short Answers:
**A) Why is DB inbound source restricted to the EC2 security group?**
> To implement the principle of least privilege, ensuring only the application servers can communicate with the database. This prevents unauthorized access from other sources and reduces the attack surface.

**B) What port does MySQL use?**
> Port 3306 (TCP)

**C) Why is Secrets Manager better than storing creds in code/user-data?**
> Secrets Manager provides automatic rotation, audit logging via CloudTrail, encryption at rest with KMS, and eliminates hardcoded credentials that could be exposed in code repositories or instance metadata.

### 3) Evidence for Audits / Labs
```bash
# Export configuration for verification
aws ec2 describe-security-groups --group-ids sg-0123456789abcdef0 > sg.json
aws rds describe-db-instances --db-instance-identifier lab-mysql > rds.json
aws secretsmanager describe-secret --secret-id lab/rds/mysql > secret.json
aws ec2 describe-instances --instance-ids i-0123456789abcdef0 > instance.json
aws iam list-attached-role-policies --role-name LabEC2Role > role-policies.json
```

**Answer these questions for each artifact**:
1. Why does this rule/configuration exist?
2. What would break if it were removed?
3. Why is broader access forbidden?
4. What security principle does this enforce?

---

**Lab Completion**: Successfully implementing this pattern demonstrates practical understanding of foundational AWS security and networking concepts that are essential for real-world cloud engineering roles.