<h1 align="center">VPC & Networking (Custom VPC) Phase 1</h1>

<br>

<details>
  <summary>Table Of Contents</summary>

  

  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/VPC%20&%20NETWORKING%20(CUSTOM%20VPC)-PHASE-1.md#-1-map-out-resources-youll-define-in-terraform">1 Map out resources you’ll define in Terraform</a>

  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/VPC%20&%20NETWORKING%20(CUSTOM%20VPC)-PHASE-1.md#-11-goal-">1.1 Goal</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/VPC%20&%20NETWORKING%20(CUSTOM%20VPC)-PHASE-1.md#-12-what-to-do">1.2 What to do</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/VPC%20&%20NETWORKING%20(CUSTOM%20VPC)-PHASE-1.md#-11-goal-">1.3 Why</a>
    
<br>


</details>

<br>

<h2 align="center">👷 1 Map out resources you’ll define in Terraform</h2>

<br>

- aws_vpc (Custom)

- aws_subnet (reference at least 2)

- aws_security_group (EC2 + RDS)

- aws_instance (EC2)

- aws_db_instance (RDS MySQL)

- aws_secretsmanager_secret (DB credentials)

- aws_iam_role & aws_iam_role_policy_attachment (EC2 → Secrets Manager)

<br>

<h2 align="center">👷 1.1 Goal </h2>

<br>

### **What is the goal?**

<br>

You should put your EC2 and RDS in the same VPC while keeping them isolated in separate subnets.

<br>

<h2 align="center">👷 1.2 What to do</h2>

<br>


**1. Create a custom VPC**

- Pick a CIDR range (e.g., 172.17.0.0/16)

**2 . Create two subnets**

- Public subnet → EC2 instance (attach Internet Gateway, for HTTP/SSH access)

- Private subnet → RDS instance (no IGW, private only)

**3. Create route tables**

- Public subnet route table → routes 0.0.0.0/0 to Internet Gateway + local VPC route

- Private subnet route table → only local VPC route (10.0.0.0/16)

**4. Attach route tables to respective subnets**

<br>

<h2 align="center">👷 1.3 Why</h2>

<br>

Doing it this way keeps EC2 publicly accessible while RDS stays private. Enforces network isolation so traffic must follow VPC routing + security groups and Prepares for Terraform-managed infrastructure and security-focused design.

After your resources have been configured you can check to confirm VPC, subnets, and route tables exist in Terraform state by running terraform plan.











