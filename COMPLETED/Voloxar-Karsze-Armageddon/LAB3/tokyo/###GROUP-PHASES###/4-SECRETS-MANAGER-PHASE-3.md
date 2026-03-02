<h1 align="center">Secrets Manager Phase 3</h1>

<br>

<details>
  <summary>Table Of Contents</summary>

  

  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-1-purpose">1 Purpose</a>

  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-11-terraform-actions">1.1 Terraform Action</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-12-why-the-secret-is-created-before-rds">1.2 Why Terraform Does NOT Store Secret Values</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-13-terraform-checkpoint">1.3 How the Secret Is Populated</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-13-terraform-checkpoint">1.4 Runtime Secret Retrieval (EC2)</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-13-terraform-checkpoint">1.5 Terraform Checkpoint</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-13-terraform-checkpoint">1.6 Security Design Decision Summary</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-13-terraform-checkpoint">1.7 Secrets Manager Is A Long Lived Resource</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-13-terraform-checkpoint">1.8 How envs uses the secret</a>
  
   
    
<br>


</details>

<br>

<h2 align="center">👷 1 Purpose</h2>

<br>

The purpose of this phase is to establish an identity-based secret retrieval model using AWS Secrets Manager. Database credentials are stored securely outside of EC2 instances and application code, and are retrieved dynamically at runtime using IAM roles. This eliminates hardcoded secrets and mirrors real-world AWS production patterns.

<br>

Terraform is used to provision infrastructure and define the existence of secrets, but does not manage secret values to prevent credential exposure in shared state.




<br>

<h2 align="center">👷 1.1 Terraform Actions</h2>

<br>

**Create the secret container**

<br>

```bash
resource "aws_secretsmanager_secret" "rds_secret" {
  name = "lab/rds/mysql"
}
```
<br>

This resource creates a Secrets Manager container only.
<br>

- **No credentials are stored here**

- **No secret values are known to Terraform**

- **The secret can safely be referenced by other modules**

- **Requires no PutSecretValue or GetSecretValue permissions**
<br>
Terraform’s responsibility ends at declaring the secret’s existence.


<br>


<h2 align="center">👷 1.2 Why Terraform Does NOT Store Secret Values</h2>

<br>

This infrastructure uses:

- **A shared S3 remote backend**

- **DynamoDB state locking**

- **Multiple operators applying Terraform**

Because Terraform state is shared:


- **Any secret value Terraform manages would be stored in plaintext in the state file**

- **All users with backend access could retrieve credentials**

- **Secrets Manager would no longer provide isolation**

Therefore:

Terraform must never be the source of truth for secret values in a shared-state environment.

This follows industry best practices where:

- **Terraform provisions infrastructure**

- **AWS services or controlled processes manage credentials**

<br>

<h2 align="center">👷 1.3 How the Secret Is Populated</h2>

<br>

The secret value is populated outside of Terraform, using one of the following approaches.

<br>

**Option A: AWS RDS–Managed Credentials (Recommended)**

```bash
resource "aws_db_instance" "db" {
  manage_master_user_password = true
}
```
<br>

With this approach:

- **AWS generates the database password**

- **The password is stored automatically in Secrets Manager**

- **Terraform never sees the secret value**

- **Optional rotation can be enabled**
  
<br>

This is the preferred production pattern.

<br>

**Option B: One-Time Bootstrap (Lab-Acceptable)**

<br>

For learning purposes, the secret value may be populated manually via:

<br>

- **AWS Console**

- **AWS CLI**

- **One-time controlled bootstrap script**
<br>

Example:

```bash
aws secretsmanager put-secret-value \
  --secret-id lab/rds/mysql \
  --secret-string '{"username":"admin","password":"REDACTED","dbname":"labdb"}'
```
<br>

Terraform remains unaware of the secret contents.
<br>
## Key points about it:
<br>

1. Purpose

    - **It injects the secret value (username/password/etc.) into your Secrets Manager container.**

    - **Terraform does not see or store this value.**

2. One-time only

    - **You run it once, after the secret container exists (aws_secretsmanager_secret.rds_secret).**

    - **After that, EC2 or your app can retrieve the secret at runtime via IAM.**

3. Manual / CLI

    - **Can be run from your local machine, admin machine, or any host with AWS CLI access.**

    - **Requires IAM permissions: secretsmanager:PutSecretValue.**

4. Safe for labs / Option B:

    - **Even though the command has the secret hardcoded temporarily, it never enters Terraform state, so it’s safe for a shared-team lab environment.**

<br>
1️⃣ What happens in your bootstrap step
aws secretsmanager put-secret-value \
  --secret-id lab/rds/mysql \
  --secret-string '{"username":"admin","password":"REDACTED","dbname":"labdb"}'


This adds a secret value to the container you created with Terraform (aws_secretsmanager_secret).

AWS stores your JSON with the RDS credentials securely.

Billing: still $0.40/month per secret — the value itself doesn’t increase the cost unless it’s huge.

2️⃣ Why it’s called “dynamic”

You’re not hardcoding the secret into Terraform.

You run the CLI once to populate the secret.

After this, EC2 or other apps can retrieve it dynamically at runtime using IAM.

3️⃣ How it fits with Terraform

aws_secretsmanager_secret → creates the empty safe (Terraform).

aws secretsmanager put-secret-value → puts the username/password in that safe (one-time bootstrap).

EC2 fetches it at runtime; Terraform does not see the value unless you use data "aws_secretsmanager_secret_version".


<br>


<h2 align="center">👷 1.4 Runtime Secret Retrieval (EC2)</h2>

<br>

At runtime:

- **EC2 instances assume an IAM role**

- **The role allows secretsmanager:GetSecretValue**

- **The application retrieves credentials dynamically**

No credentials are stored in:

- **EC2 user data**

- **AMIs**

- **Application source code**

- **Terraform variables**
<br>
This enforces a runtime identity-based trust model.

<br>


<h2 align="center">👷 1.5 Terraform Checkpoint</h2>

<br>

After terraform apply, verify that the secret container exists:
<br>
```bash
aws secretsmanager describe-secret \
  --secret-id lab/rds/mysql
```
<br>

## Expected result:
<br>

- **Secret exists**

- **No Terraform-managed secret value is present**

If populated externally, retrieving the value will return a JSON payload containing credentials.

<br>

<h2 align="center">👷 1.6 Security Design Decision Summary</h2>

<br>

| Decision                                 | Reason                            |
|------------------------------------------|-----------------------------------|
| Secret container managed by Terraform    | Safe and non-sensitive            |
| Secret values excluded from Terraform    | Prevents leakage into shared state|
| Runtime retrieval via IAM                | Eliminates static credentials     |
| RDS or external bootstrap owns passwords | Aligns with real AWS practices    |

<br>

<h2 align="center">👷 1.7 Secrets Manager Is A Long Lived Resource</h2>

<br>

Typically you DO NOT put long-lived resources in a root that you routinely destroy. As Secrets Manager is a long-lived resource, so what you should do is keep envs for ephemeral infrastructure such as your



- **VPC**

- **Subnets**

- **EC2**

- **Security groups**

- **RDS (if you tear it down)**

<br>

These can safely be destroyed.

<br>

In this case you should create a second root for secrets. Inside this directory should be the backend.tf and the main.tf which creates the long lived Secrets Manager Container.

<br>

secrets/backend.tf:

```bash
terraform {
  backend "s3" {
    bucket         = "project-armageddon-tf-state"
    key            = "lab1/a/secrets.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

<br>

secrets/main.tf:

<br>

```bash
provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name = "lab-1a/rds/mysql"
}
```

<br>

Run once:

<br>

```bash
cd LAB1/a/secrets
terraform init
terraform apply
```

<br>

<h2 align="center">👷 1.8 How envs uses the secret</h2>


In envs, you do not create the secret. You only reference it.

```bash
data "aws_secretsmanager_secret" "rds" {
  name = "lab-1a/rds/mysql"
}
```

<br>


## Key Takeaway

Terraform provisions the vault, not the keys. Secret values are generated and managed by AWS or controlled processes, while applications retrieve secrets dynamically using identity.

