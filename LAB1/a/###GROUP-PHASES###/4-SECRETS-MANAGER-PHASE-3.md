<h1 align="center">Secrets Manager Phase 3</h1>

<br>

<details>
  <summary>Table Of Contents</summary>

  

  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-1-purpose">1 Purpose</a>

  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-11-terraform-actions">1.1 Terraform Action</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-12-why-the-secret-is-created-before-rds">1.2  Why the Secret Is Created Before RDS</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-13-terraform-checkpoint">1.3 Terraform checkpoint</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-13-terraform-checkpoint">1.4 Why you hardcode the secrets manager with a username and password?</a>

   
    
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


<br>


<h2 align="center">👷 1.4 Why you hardcode the secrets manager with a username and password?</h2>

<br>

## Important to know

If you hardcode the username/password directly in Terraform, you must treat that as sensitive and protect it.
Secrets Manager is dynamic at runtime, but Terraform is still used to bootstrap the initial secret.

This lab teaches the **runtime pattern**, not **perfect secret bootstrapping hygiene** — but we still do it safely.

<br>

## Why This Is Still OK in the Lab?

<br>

There are two different moments in time:

<br>

**Provisioning time (Terraform)**

- Terraform needs some value to create the secret

- This is a one-time bootstrap

- The secret then lives in Secrets Manager, not in EC2 or code

<br>

**Runtime (EC2 application)**

<br>

- EC2 never sees hardcoded credentials

- EC2 retrieves the secret dynamically using IAM

- Password rotation does not require app or server changes

  <br>

The security win is at runtime, which is what employers care about most.

