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