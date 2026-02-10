SEIR Lab 1: Database Identity and Origin Security
Status: COMPLETE (Final Result: GREEN/PASS)

Region: ap-northeast-1 (Tokyo)

Author: Lew

1. Project Overview
Lab 1 focuses on the "First Line of Defense": securing the communication between the application layer (EC2) and the data layer (RDS). The goal was to eliminate hard-coded credentials and wide-open networking in favor of IAM Roles and Security Group Referencing.

2. Lab 1A: Base Networking & RDS Implementation
Infrastructure: Provisioned a MySQL RDS instance (lew-rds01) within a private subnet.

Security Posture: Ensured PubliclyAccessible was set to False, isolating the database from the public internet.

Connectivity: Established an EC2 Instance (i-0ee4ab7361dc2f1c8) as the authorized application host.

3. Lab 1B: Security Group "Handshake" (SG-to-SG)
Instead of using CIDR blocks (IP ranges), which are brittle and less secure, we implemented Security Group Referencing:

Source: sg-03f4aba799ec651a0 (EC2 Application SG).

Destination: sg-041f924a7e053e392 (RDS Database SG).

Protocol: Port 3306 (MySQL).

Result: The RDS instance only accepts traffic if it originates from an instance explicitly tagged with the Application Security Group.

4. Lab 1C: Identity-Based Access (IAM Roles)
We eliminated the need for AWS_ACCESS_KEY environment variables by using Instance Profiles:

IAM Role: lew-ec2-role01.

Instance Profile: lew-instance-profile01.

Capability: The EC2 instance assumes this role to automatically gain permissions to call AWS services (Secrets Manager, SSM) without stored credentials.

5. Lab 1C Bonus (A-F): Secrets Manager & Integrity
We moved beyond plain-text passwords to a managed secret rotation model:

A. Secret Creation: Stored database credentials in Secrets Manager (lew/rds/mysql).

B. SSM Parameter Store: Created a pointer at /lab/db/ to store metadata, facilitating a "Source of Truth" for app config.

C. Decoupling: The application now requests the Path rather than the Password.

D. Drift Check: Verified that SSM metadata matches the actual RDS endpoint.

E. Least Privilege: Verified that the EC2 Role can only Describe the specific secret required for the lab.

F. Verification: Successfully ran gate_secrets_and_role.sh to prove the identity chain works.

6. Technical Gate Results
The following results were captured from the automated SEIR Gate Suite:

Gate 1: Secrets & Role
Secret Existence: PASS (lew/rds/mysql found).

IAM Profile: PASS (Attached to EC2).

Role Resolution: PASS (lew-ec2-role01 identified).

Gate 2: Network & DB
Public Accessibility: PASS (False).

Port Discovery: PASS (3306).

SG-to-SG Ingress: PASS (Verified EC2 SG → RDS SG).

7. Troubleshooting Log
Issue: sed unused label errors on macOS.

Resolution: Identified as a BSD vs GNU sed compatibility issue. Verified that core AWS logic remained unaffected.

Issue: Off-instance caller warning.

Resolution: Confirmed this is expected when running gates from a local workstation using personal IAM credentials rather than the EC2 role itself.

8. Final Artifacts
gate_result.json: Machine-readable evidence.

gate_secrets_and_role.json: Identity evidence.

gate_network_db.json: Networking evidence.

This lab demonstrates a fully "cloaked" database origin where access is governed by identity rather than just network location.