<h1 align="center">Secrets Manager Phase 3</h1>

<br>

<details>
  <summary>Table Of Contents</summary>

  

  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/edit/main/LAB1/a/3-SECURITY-GROUPS-PHASE-2.md#-1-goal">1 Purpose</a>

  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/edit/main/LAB1/a/3-SECURITY-GROUPS-PHASE-2.md#-terraform-action">1.1 Terraform Action</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/edit/main/LAB1/a/3-SECURITY-GROUPS-PHASE-2.md#-12-why-this-design-matters">1.2  Why the Secret Is Created Before RDS</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/edit/main/LAB1/a/3-SECURITY-GROUPS-PHASE-2.md#-13-terraform-checkpoint">1.3 Terraform checkpoint</a>
    
<br>


</details>

<br>

<h2 align="center">👷 1 Purpose</h2>

To store database credentials securely outside of code and infrastructure, so the EC2 instance can retrieve them dynamically at runtime.
This prevents hardcoding passwords and establishes the identity-based trust model used in real AWS environments. In this phase, Secrets Manager is used to securely store database credentials before RDS is created, ensuring the application can retrieve them dynamically without hardcoded secrets.




<br>

<h2 align="center">👷 1.1 Terraform Actions</h2>


**Create the secret container**

<br>

```bash
resource "aws_secretsmanager_secret" "rds_secret" {
  name = "lab/rds/mysql"
}
```
<br>

This resource creates a secure location in AWS Secrets Manager where the database credentials will live.


**Store the secret value**

```bash
resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_secret.id

  secret_string = jsonencode({
    username = "admin"
    password = "StrongPassword123!"
    host     = "PLACEHOLDER"
    port     = 3306
    dbname   = "labdb"
  })
}
```

<br>

- username and password match the RDS master credentials

- host is a placeholder and will be updated after RDS is created

- port and dbname define connection defaults used by the application

<br>

The EC2 instance will later retrieve this JSON at runtime.


<br>


<h2 align="center">👷 1.2 Why the Secret Is Created Before RDS</h2>

<br>

- It forces credentials to exist independently of the database

- It Prevents hardcoding secrets in Terraform, AMIs, or user data

- Mirrors real-world workflows where secrets are managed separately from infrastructure

- RDS will be created using the same credentials stored here, and the host value is updated once the RDS endpoint is known.


<h2 align="center">👷 1.3 Terraform Checkpoint</h2>

<br>

**After terraform apply, verify that the secret exists and contains credentials:**

```bash
aws secretsmanager get-secret-value \
  --secret-id lab/rds/mysql
```

**Expected output:**

A JSON object containing at least:

- username

- password

- host

- port

At this stage, host may still be a placeholder — that is expected.

**What This Proves**

- Database credentials are not stored in code or EC2

- Secrets are managed centrally and securely

- The application will rely on IAM identity, not static credentials
