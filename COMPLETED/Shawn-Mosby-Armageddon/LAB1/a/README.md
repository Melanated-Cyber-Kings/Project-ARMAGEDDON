# EC2 → RDS Integration Lab (Lab 1a)

**Foundational Cloud Application Pattern using AWS and Terraform**

---

## 📌 Purpose

This lab teaches one of the **most common real-world AWS architectures**:

- Compute on **Amazon EC2**
- A managed relational database on **Amazon RDS (MySQL)**
- Secure networking with **VPCs and Security Groups**
- Credential management using **AWS Secrets Manager**
- Infrastructure as Code using **Terraform**

The application itself is intentionally minimal.

> The goal is to understand **infrastructure design, security boundaries, IAM trust, and Terraform workflows** — not application logic.

This pattern appears in:
- Enterprise internal tools  
- SaaS backends  
- Legacy migrations  
- Cloud security assessments  
- AWS interviews  

---

## 🧱 Architecture Overview
<br>

This lab builds a **2-tier AWS architecture**:

- VPC with public and private subnets
- EC2 instance in a public subnet (application tier)
- RDS (MySQL) in a private subnet (database tier)
- IAM role attached to EC2 for AWS API access
- AWS Secrets Manager to store database credentials
- Security Groups controlling network traffic
- Terraform remote state stored in S3 with DynamoDB locking

Infrastructure is defined using **reusable Terraform modules**, then assembled in an **environment configuration**.

---



### Core Components

- **EC2 Instance**
  - Runs a simple application
  - Lives in a public subnet
  - Uses an IAM role (no static credentials)

- **Amazon RDS (MySQL)**
  - Lives in private subnets
  - Not publicly accessible
  - Allows inbound traffic only from the EC2 security group (TCP 3306)

- **AWS Secrets Manager**
  - Stores database credentials
  - Accessed dynamically by EC2 using IAM

- **IAM**
  - EC2 assumes an IAM role
  - Temporary credentials are provided automatically
  - No access keys are stored on disk

---

## 🔄 Logical Flow

1. User sends an HTTP request to the EC2 instance
2. EC2 retrieves database credentials from Secrets Manager
3. EC2 initiates a MySQL connection to RDS
4. Data is read or written
5. Results are returned to the user

> **Important:**  
> EC2 initiates all connections.  
> RDS never initiates traffic or API calls.

---

## How Bootstrap Works

Terraform state must exist **before** shared infrastructure can be managed safely.

The `bootstrap/` directory is used **once** to create:

- An S3 bucket for Terraform remote state
- A DynamoDB table for state locking

### Bootstrap Flow

```bash
cd bootstrap
terraform init
terraform apply
```

After this:

- Terraform state is stored remotely

- State locking is enforced

- The bootstrap/ directory is never modified again

---

## 📁 Repository Structure

### VS Code View

<div align="center">
  <img src="Images/Repo-Structure.png" alt="image1" width="800"/>
</div>

---

## 🌍 Each Environment

Each environment:

- References reusable modules from `modules/`
- Defines environment-specific variables
- Uses the remote backend created during the bootstrap process

---

## ✅ What This Enables

- Multiple environments (lab, dev, prod)
- Shared Terraform state across team members
- Safe and consistent collaboration

---

## 🔍 CI / Validation (No Auto-Deploy)

This repository uses **GitHub Actions** to automatically:

- Format Terraform code using `terraform fmt`
- Initialize Terraform **without a backend**
- Validate Terraform configuration syntax

<br>

“The CI/CD pipeline checks Terraform quality and correctness. It does not deploy infrastructure. All real infrastructure changes are applied manually using a shared backend.”
---

## 🚫 No Automatic Deployment

Infrastructure is **not deployed automatically**.

All real `terraform apply` actions are:

- Performed manually
- Run locally
- Executed against a shared remote backend (S3 + DynamoDB)

This ensures **safety, transparency, and learning clarity**.

---

## 👩‍💻 How The Group Contributes

Students are expected to:

- Fork/clone the repository
- Create feature branches
- Make pushes to those feature branches 
- Submit Pull Requests
- Pass Terraform validation checks
- Receive review feedback

This simulates **real-world infrastructure workflows** without risking AWS resources.
