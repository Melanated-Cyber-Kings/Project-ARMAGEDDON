<h1 align="center">Security Groups Phase 2</h1>

<br>

<details>
  <summary>Table Of Contents</summary>

  

  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/VPC%20&%20NETWORKING%20(CUSTOM%20VPC)-PHASE-1.md#-1-map-out-resources-youll-define-in-terraform">1 Goal</a>

  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/VPC%20&%20NETWORKING%20(CUSTOM%20VPC)-PHASE-1.md#-11-goal-">1.1 Terraform Action</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/VPC%20&%20NETWORKING%20(CUSTOM%20VPC)-PHASE-1.md#-12-what-to-do">1.2 What this design matters</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/VPC%20&%20NETWORKING%20(CUSTOM%20VPC)-PHASE-1.md#-11-goal-">1.3 Why</a>
    
<br>


</details>

<br>

<h2 align="center">👷 1 Goal</h2>

The goal is for you to control which resources are allowed to communicate at the network level. Security groups act as virtual firewalls inside the VPC. 
They decide who can talk to whom before any application logic, usernames, or passwords are involved.



<br>

<h2 align="center">👷 Terraform Actiom</h2>


**EC2 Security Group (sg-ec2-lab1a)**

- This security group controls access to the application server.
- In this lab, the EC2 instance is the application server. So when the documentation says “application server”, it is referring to the EC2 instance running the Flask app.

**Inbound rules:**

- Allow HTTP (TCP 80) from 0.0.0.0/0 so the application can be accessed from a browser

- Allow SSH (TCP 22) from your IP only (temporary, for troubleshooting)

**Outbound rules:**

- Allow all outbound traffic

- This lets EC2 reach AWS services (Secrets Manager) and the database


**RDS Security Group (sg-rds-lab1a) — Critical Rule**

This security group protects the database.

**Inbound rules:**

- Allow MySQL (TCP 3306)

- Source = EC2 security group ID (not a CIDR block)

**This means:**

- Only EC2 instances using the EC2 security group can reach the database

- No IP addresses are trusted

- The database is unreachable from the internet

**Outbound rules:**

- Allow all outbound traffic (default)
- Allowing all outbound traffic is safe because the RDS security group still strictly controls inbound access, and security groups automatically allow response traffic for approved connections.

<br>

<h2 align="center">👷 1.2 Why this design matters</h2>

This design matters because 

- Security groups enforce **least privilege** at the network layer

- Referencing a security group instead of an IP:

  - Prevents accidental exposure

  - Works even if EC2 IP addresses change

  - Matches real-world AWS security practices

Traffic is blocked before authentication, reducing attack surface

<br>


<h2 align="center">👷 1.3 Terraform checkpoint</h2>


After applying Terraform, verify that the RDS security group inbound rule references the EC2 security group ID.

**This confirms:**

- EC2 is explicitly trusted to connect to RDS
- No other network sources are allowed

<br>

After running:


terraform apply


you must confirm that the RDS security group inbound rule references the EC2 security group, not an IP range.

Step 1: Get the RDS Security Group Details (AWS CLI)

Run:

aws ec2 describe-security-groups \
  --group-names sg-rds-lab \
  --query "SecurityGroups[].IpPermissions"

Step 2: What to Look For

In the output, you should see:

FromPort: 3306

ToPort: 3306

IpProtocol: tcp

UserIdGroupPairs containing the EC2 security group ID

Example (simplified):

[
  {
    "FromPort": 3306,
    "ToPort": 3306,
    "IpProtocol": "tcp",
    "UserIdGroupPairs": [
      {
        "GroupId": "sg-0abc123ec2sg"
      }
    ]
  }
]


What matters:

✅ UserIdGroupPairs is present

❌ No IpRanges like 0.0.0.0/0

Step 3: Why This Confirms Correct Security

This proves:

Only EC2 instances in sg-ec2-lab can reach the database

No IP addresses or public networks are trusted

Database access is enforced at the network level

One-Sentence Summary for Documentation

After applying Terraform, the RDS security group is verified by confirming its inbound MySQL rule references the EC2 security group ID instead of a CIDR block.



