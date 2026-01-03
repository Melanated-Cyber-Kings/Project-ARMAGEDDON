<h1 align="center">VPC & Networking (Custom VPC) Phase 1</h1>

<br>

<details>
  <summary>Table Of Contents</summary>

  

  - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-21-ideation-phase-0-">1 Goal</a>
    - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-211-actors">1.1 What to do</a>
    - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-212-trust-problems">1.2 Why</a>
    - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-213-iam">1.3 IAM</a>
    



</details>

<br>

<h2 align="center">🤔 1 Goal </h2>

<br>

### **What is the goal?**


You should put your EC2 and RDS in the same VPC while keeping them isolated in separate subnets.

<br>

<h2 align="center">🤔 What to do</h2>

<br>

**1. Create a custom VPC**

-Pick a CIDR range (e.g., 172.17.0.0/16)

**2 . Create two subnets**

-Public subnet → EC2 instance (attach Internet Gateway, for HTTP/SSH access)

-Private subnet → RDS instance (no IGW, private only)

**3. Create route tables**

-Public subnet route table → routes 0.0.0.0/0 to Internet Gateway + local VPC route

-Private subnet route table → only local VPC route (10.0.0.0/16)

**4. Attach route tables to respective subnets**



