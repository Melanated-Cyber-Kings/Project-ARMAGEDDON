# Lab 1C: The Hardened Monolith

**EC2 → RDS + Secrets/Params + Observability + Incident Alerts**

## Project Overview
This project codifies the operational standards established in Lab 1B into a production-hardened, Terraform-managed environment. While Lab 1B focused on the "Day 2" operations of manual recovery, secret management, and incident response, Lab 1C moves those capabilities into an Infrastructure as Code (IaC) framework. The environment is designed to be programmatically repeatable, reviewable, and recoverable by embedding AWS Secrets Manager and proactive CloudWatch alerting directly into the Terraform state.

### The Evolution: From Lab 1B to 1C
This lab takes the "Mid-Level Engineer" capabilities demonstrated in Lab 1B and scales them through automation:

**From Manual Ops to IaC:** Instead of creating Parameter Store entries and Secrets via the CLI/Console, Lab 1C manages the entire lifecycle (Creation, Policy Assignment, and Rotation) via Terraform.

**Hardening the Handshake:** We moved from "knowing how to recover" to "automating the recovery path." The EC2 User Data is now programmatically linked to the Secrets Manager and SSM outputs generated during the Terraform apply.

**Codified Observability:** The Metric Filters and Alarms that were manually tested in 1B are now declared as code, ensuring that every new environment deployed has the exact same "Incident Response" baseline.

## Architecture Design
The infrastructure is contained within a single regional VPC (ap-northeast-1) but is logically tiered to protect data and configuration integrity.

### 1. Network & Compute
**- VPC Infrastructure:** Implements a standard 3-tier architecture with public subnets for the NAT Gateway and private subnets for the App and Database tiers.

**- EC2 App Host:** Stateless application server managed via Terraform, utilizing a Launch Template for consistent deployments.

**- IAM Role/Profile:** Implements the Principle of Least Privilege, granting the EC2 instance specific permissions to fetch secrets and write logs without broad administrative rights.

### 2. Security & Data Management
**- RDS (Private):** MariaDB instance isolated in private subnets, accepting traffic exclusively from the EC2 Security Group on port 3306.

**- Systems Manager (SSM) Parameter Store:** Manages non-sensitive configuration values under the /lab/db/* namespace for environmental flexibility.

**- Secrets Manager:** Securely stores and encrypts database credentials, removing the need for hardcoded passwords in version control or User Data scripts.

## DevOps Workflow (Observability)
This project emphasizes operational resilience by closing the loop between logging, detection, and notification.
### Incident Lifecycle
**- Logging:** The EC2 application tier streams all system and connection logs to a centralized CloudWatch Log Group.

**- Detection:** A Metric Filter monitors logs for specific failure patterns (e.g., DBConnectionError).

**- Alerting:** A CloudWatch Alarm triggers an SNS notification when 3 or more errors occur within a 5-minute evaluation period.

**- Notification:** An SNS Topic dispatches an immediate email alert to the sysadmin to minimize Mean Time to Recovery (MTTR).

## Security & Compliance
**Secret Injection:** Credentials are never stored on disk. They are fetched at runtime via the AWS CLI and injected directly into the application memory.

**Auditable Infrastructure:** By using Terraform, every security group rule and IAM policy is version-controlled and peer-reviewable.

**Encrypted Credentials:** All sensitive data in Secrets Manager is encrypted at rest using AWS KMS.

## Verification
Connectivity and security can be verified using the following CLI steps:

Verify Secrets Retrieval via IAM Role aws secretsmanager get-secret-value --secret-id db_creds --query "SecretString" --output text

Verify RDS Connectivity using SSM Parameters mysql -h $(aws ssm get-parameter --name "/lab/db/endpoint" --query "Parameter.Value" --output text) -u <username> -p

## Data Flow Architecture
The following flow describes the "Handshake" process of a hardened application boot:

**- Instance Boot:** EC2 initializes and runs the User Data script. 
**- Identity Check:** The instance uses its IAM Role to authenticate with AWS service endpoints. 
**- Config Fetch:** The script pulls the DB Endpoint from SSM Parameter Store. 
**- Secret Fetch:** The script pulls the DB Password from AWS Secrets Manager. 
**- Connection:** The App establishes a secure tunnel to the RDS instance in the private subnet. 
**- Log Export:** The CloudWatch Agent begins streaming application logs to the Tokyo Hub.

## Troubleshooting & Resolution Log (Incident Runbook)
During the "Incident Simulation" phase, the following operational hurdles were resolved:
### 1. The "Access Denied" Secret Error
**Issue:** EC2 was unable to fetch secrets despite the aws_secretsmanager_secret existing.

**Cause:** The IAM Instance Profile lacked the secretsmanager:GetSecretValue permission for the specific ARN.

**Resolution:** Updated the aws_iam_policy to include explicit read permissions for the Secret resource.

### 2. The "Quiet Alarm" (Metric Filter Failure)
**Issue:** Manual errors were injected into logs, but the CloudWatch Alarm remained in an OK state.

**Cause:** The Metric Filter pattern was case-sensitive and did not match the application's output log format.

**Resolution:** Standardized the log output and updated the Metric Filter to match the exact string: "DBConnectionError".

### 3. RDS Security Group Lockdown
**Issue:** The EC2 instance timed out when trying to reach the RDS endpoint.

**Cause:** The RDS Security Group allowed traffic from the VPC CIDR, but not specifically from the EC2 Security Group ID (breaking the principle of security groups as a source).

**Resolution:** Refactored the Inbound rule to reference the aws_security_group.app_sg.id as the source.

## Teardown & Lifecycle Management
Since Lab 1C is a monolith, destruction is straightforward but must follow the dependency tree to prevent errors.
### - Phase 1: Dependency Cleanup:
Run terraform destroy. Terraform will automatically identify that the SNS subscriptions and Metric Filters must be removed before the Log Groups.

### - Phase 2: Compute & Data:
The ASG and RDS instances are terminated. Note: If skip_final_snapshot is set to false, the destroy will pause to create a backup.

### - Phase 3: Network:
The VPC, Subnets, and NAT Gateway are removed once all ENIs (Elastic Network Interfaces) are released.

## Teardown Best Practices
### Manual Snapshots: 
Always verify if a final RDS snapshot is required by the business before running the destroy command.

### CloudWatch Cleanup: 
Ensure Log Groups are deleted to avoid ongoing storage costs for high-volume logs.

## Interview Presentation: "The Hardened Monolith"
### 1. The Challenge (The "Hook")
"Most companies struggle with credential leakage and 'silent' failures. For Lab 1C, I was tasked with taking a functional environment and making it production-ready by automating secret management and building an automated incident response loop."

### 2. The Solution (The "Meat")
"I used Terraform to build a secure 3-tier system. I replaced all hardcoded credentials with AWS Secrets Manager and SSM Parameter Store. I then closed the operational loop by creating a CloudWatch-to-SNS pipeline that alerts engineers within seconds of a database connection failure."

### 3. Technical Hurdle & Resolution (The "Expertise")
"The biggest challenge was configuring the IAM Instance Profile correctly. I had to ensure the EC2 had exactly enough permission to read its configuration but not enough to modify the database or delete logs. This 'Least Privilege' approach is what separates a student project from an enterprise-grade build."

### 4. The Result (The "Proof")
"The build was validated by a simulated incident. I manually triggered a connection failure, verified that the CloudWatch Metric Filter caught the event, and confirmed that an SNS alert was successfully delivered to my inbox."

## Potential Interview Questions (and how to answer)
**- "Why use Secrets Manager instead of just putting the password in a Terraform variable?"**

"Variables are often stored in plain text in the `terraform.tfstate` file. By using Secrets Manager, the password is encrypted at rest, can be rotated without downtime, and is never exposed in the source code or state files."
**- "What is the difference between SSM Parameter Store and Secrets Manager?"**

"I use Parameter Store for non-sensitive data like endpoints or feature flags because it is cost-effective. I use Secrets Manager for sensitive data like passwords because it offers advanced encryption and built-in secret rotation capabilities."
**- "How does your observability stack help reduce Mean Time to Repair (MTTR)?"**

"Instead of waiting for a user to report that the site is down, the system proactively alerts us the moment the error threshold is hit. This allows the team to begin troubleshooting before the failure results in a total outage."
**- "What happens if the CloudWatch Agent fails on the EC2 instance?"**

"This would result in 'Observability Silence.' To mitigate this, I would eventually add a 'Missing Data' policy to the CloudWatch Alarm so that if logs stop flowing, the alarm moves to an `INSUFFICIENT_DATA` state, which also triggers an SNS alert."

## Business Value & Real-World Use Cases
IaC and Observability are the dual pillars of modern DevOps. This architecture directly translates to business savings:
### 1. Regulatory Compliance (SOC2 / HIPAA)
Auditors require proof that credentials are not hardcoded and that system access is logged. Value: This setup provides an automated audit trail of who accessed what secret and when.

### 2. Disaster Recovery
If a region goes down, a business needs to be back online in minutes. Value: Using Terraform ensures that the entire hardened stack can be redeployed to a new region with a single command.

### 3. Operational Scalability
As a company grows from 1 server to 100, manual monitoring becomes impossible. Value: The CloudWatch Metric Filter automatically scales with the ASG, monitoring every new instance that joins the cluster without manual intervention.

## Executive Summary: Why This Matters

For a business, this architecture provides:

**Security:** Protects the company from "Insider Threats" and credential leakage.

**Reliability:** Shifts the company from reactive firefighting to proactive incident management.

**Efficiency:** Automates the "Boring" parts of infrastructure so engineers can focus on building features rather than fixing login issues.

# Lab 1C Bonus-A: The "Dark VPC" (PrivateLink & SSM)

## Design Goals: Zero-Trust Isolation
The objective of Bonus-A is to eliminate the two most common attack vectors in cloud environments: Public IP addresses and SSH (Port 22). This is achieved by moving compute into a "Dark" state where the instance has no route to the internet, relying instead on **VPC Endpoints (AWS PrivateLink)** to communicate with the AWS control plane.
### 1. Zero-Exposure Compute
**- Private-Only EC2:** The instance is launched without a Public IP (associate_public_ip_address = false).

**- No SSH Required:** Administrative access is managed via AWS Systems Manager (SSM) Session Manager. This eliminates the need for managing SSH keys or opening Port 22 in Security Groups.

### 2. AWS PrivateLink (VPC Endpoints)
To allow the private instance to reach AWS services without a NAT Gateway or Internet Gateway, Interface Endpoints were implemented for:
**- Management:** ssm, ec2messages, ssmmessages (Enables Session Manager).

**- Observability:** logs (Enables CloudWatch log streaming).

**- Security:** secretsmanager and kms (Enables credential retrieval).

**- Storage:** An S3 Gateway Endpoint was utilized to allow the instance to access S3 buckets (often used for OS package repos or "Golden AMIs") without incurring NAT data transfer costs.

## Bonus-A Verification (CLI)
The following tests were performed to prove the environment is truly isolated and managed via PrivateLink:

### 1. Prove EC2 is Private (No Public IP)
aws ec2 describe-instances --instance-ids <INSTANCE_ID> --query "Reservations[].Instances[].PublicIpAddress" Expected Output: null

### 2. Prove VPC Endpoints Exist
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=<VPC_ID>" --query "VpcEndpoints[].ServiceName" Expected Output: List includes ssm, logs, secretsmanager, and s3.

### 3. Prove Session Manager Connectivity (No SSH)
aws ssm describe-instance-information --query "InstanceInformationList[].InstanceId" Expected Output: The private Instance ID appears, confirming the SSM Agent is communicating via the Interface Endpoints.

### 4. Prove Private API Access
From within the SSM Session: aws ssm get-parameter --name /lab/db/endpoint aws secretsmanager get-secret-value --secret-id <your-secret-name>

## Why This Matters to Employers
Standard for Regulated Industries: Private compute combined with SSM is the mandatory standard in Finance, Healthcare, and Government sectors.

### Cost & Security Optimization: 
VPC Endpoints reduce the "surface area" for attacks and, in many cases, provide a more reliable path to AWS APIs than a central NAT Gateway.

### Least Privilege (IAM): 
In this bonus, IAM policies were further tightened so that GetSecretValue is restricted to one specific Secret ARN and GetParameter is restricted to the /lab/db/ path.

## Executive Summary: The "Real-World" Shift
In a mature Cloud-Native organization, engineers do not "SSH into boxes." Instead, they ship changes via Terraform and manage instances via Session Manager. By removing the dependency on NAT for AWS APIs, we have created an architecture that is more resilient to internet-side failures and significantly harder to breach.

# Lab 1C Bonus-B: Enterprise Web Ingress (TLS, WAF, & Dashboards)

## Design Goals: Production-Grade Exposure
The objective of Bonus-B is to expose the private application to the internet safely using a **Managed Ingress** pattern. This ensures that while the EC2 instances remain hidden in private subnets, users can reach them via a secure, encrypted, and monitored URL.
### 1. Secure Managed Ingress
**- Public Application Load Balancer (ALB):** Acts as the "Front Door." It resides in public subnets and handles all inbound internet traffic.

**- TLS Termination (ACM):** Implements HTTPS via AWS Certificate Manager. The ALB terminates SSL using a certificate for app.chewbacca-growl.com, ensuring data in transit is encrypted.

**- Private Target Group:** The ALB routes traffic securely to the private EC2 instances. The EC2 instances are configured to allow traffic only from the ALB's Security Group.

### 2. Edge Security & Observability
**- WAF (Web Application Firewall):** Attached directly to the ALB to protect against common web exploits (SQL injection, Cross-Site Scripting) and rate-limit abusive traffic.

**- CloudWatch Dashboard:** A centralized "Single Pane of Glass" showing real-time metrics for ALB Request Count, Target Response Time, and 5xx Errors.

**- 5xx Spike Alarm:** An SNS-linked CloudWatch alarm that triggers if the ALB returns multiple server errors, alerting the team to application-level failures.

## DevOps Workflow: DNS & Certificate Validation
A critical part of this bonus was the automated "Handshake" of the domain name using **Route 53**:

**Hosted Zone:** Managed the DNS records for chewbacca-growl.com.

**ACM Validation:** Used Terraform to create the CNAME records required by AWS to prove domain ownership and issue the SSL certificate automatically.

**Alias Record:** Created a Route 53 Alias record to map app.chewbacca-growl.com directly to the ALB’s DNS name.

## Bonus-B Verification (CLI)
The following commands verify that the enterprise ingress stack is active and protected:

### 1. Verify ALB State
aws elbv2 describe-load-balancers --names chewbacca-alb01 --query "LoadBalancers[0].State.Code" Expected Output: "active"

### 2. Verify HTTPS Listener (Port 443)
aws elbv2 describe-listeners --load-balancer-arn <ALB_ARN> --query "Listeners[].Port" Expected Output: List includes 443.

### 3. Verify WAF Protection
aws wafv2 get-web-acl-for-resource --resource-arn <ALB_ARN> Expected Output: Detailed JSON of the Web ACL attached to the Load Balancer.

### 4. Verify Observability (Dashboard & Alarm)
aws cloudwatch list-dashboards --dashboard-name-prefix chewbacca aws cloudwatch describe-alarms --alarm-name-prefix chewbacca-alb-5xx

## Why This Matters to Employers
**Full-Stack Security:** You aren't just managing servers; you are managing the entire user journey from the browser to the database.

**Certificate Lifecycle Management:** Automating ACM validation via Terraform is a key skill for preventing "expired certificate" outages.

**Edge Protection:** Familiarity with WAF and ALB security groups shows a "Defense in Depth" mindset.

**Proactive Monitoring:** Creating Dashboards and 5xx Alarms demonstrates that you care about the User Experience (UX) and uptime.

## Executive Summary: From Student to Junior Cloud Engineer
With the completion of Bonus-B, this project mirrors a standard enterprise deployment. By combining **Private Compute (Bonus-A)** with **Managed Ingress and TLS (Bonus-B)**, we have built a system that is secure by default, encrypted in transit, and fully observable. This is the exact pattern used by modern DevOps teams to ship production-ready applications.

# Lab 1C Bonus-C: Full DNS Automation (Route 53 & ACM DNS Validation)
## Design Goals: Hands-Off Identity
The objective of Bonus-C is to achieve "Zero-Touch" certificate management. Rather than manually clicking through emails to validate domain ownership, this lab uses **DNS Validation**. Terraform programmatically creates the necessary CNAME records in Route 53 to prove ownership, enabling AWS to issue and renew SSL certificates automatically.
### 1. Automated Domain Handshake
**- Route 53 Hosted Zone:** Manages the authoritative records for chewbacca-growl.com.

**- DNS Validation Records:** Terraform calculates the specific CNAME records required by ACM and injects them into the Hosted Zone. This "Challenge/Response" occurs entirely within the AWS backbone.

**- The ALIAS Record:** Unlike a standard CNAME, we use an A-Record Alias to point app.chewbacca-growl.com to the ALB. This is an AWS-specific optimization that resolves faster and is cost-free for Alias queries.

### 2. High-Integrity HTTPS Listener
**- Listener Dependencies:** The HTTPS listener on Port 443 is configured with a depends_on block. This ensures the "Hangar Bay" (the ALB) doesn't open until the "Shields" (the SSL Certificate) are fully validated and issued.

**- TLS 1.3 Security Policy:** Implements the ELBSecurityPolicy-TLS13-1-2-2021-06 policy, enforcing modern encryption standards and disabling vulnerable legacy protocols.

## DevOps Workflow: The Navigation Computer
This lab introduces conditional logic to the infrastructure. By using a `manage_route53_in_terraform` boolean, the stack can either create a new Hosted Zone or hook into an existing one—providing the flexibility required for real-world enterprise migrations.

## Bonus-C Verification (CLI)
The following commands confirm that the "Nav Computer" has correctly mapped your domain to your infrastructure:

### 1. Confirm Hosted Zone Existence
aws route53 list-hosted-zones-by-name --dns-name chewbacca-growl.com --query "HostedZones[].Id" Expected Output: The unique ID for your Hosted Zone.

### 2. Confirm App Record Path
aws route53 list-resource-record-sets --hosted-zone-id <ZONE_ID> --query "ResourceRecordSets[?Name=='app.chewbacca-growl.com.']" Expected Output: JSON showing the record pointing to your ALB's DNS name.

### 3. Confirm Certificate Status
aws acm describe-certificate --certificate-arn <CERT_ARN> --query "Certificate.Status" Expected Output: "ISSUED"

### 4. The Final Test: End-to-End HTTPS
curl -I https://app.chewbacca-growl.com Expected Output: HTTP/1.1 200 OK

# Lab 1C Bonus-D: Apex Routing & Audit Logging (The "Incident Fuel")
## Design Goals: Professional Presence & Compliance
The objective of Bonus-D is two-fold: providing a seamless user experience by supporting the "Naked" domain (Zone Apex) and ensuring total operational visibility through ALB Access Logs. This represents the "Audit-Ready" state required for SOC2 or HIPAA compliance.
### 1. Zone Apex Mapping (chewbacca-growl.com)
**- Naked Domain Support:** Users often forget subdomains like app.. This lab implements an ALIAS record at the Zone Apex (@), mapping the root domain chewbacca-growl.com directly to the ALB.

**- Route 53 Intelligence:** Since the Apex of a domain cannot be a CNAME (due to DNS specs), using the Route 53 Alias allows us to map the root domain to an AWS resource while maintaining high performance.

### 2. ALB Access Logging (The "Black Box")
**- S3 Audit Vault:** Configured the ALB to stream detailed access logs into a dedicated, encrypted S3 bucket. 
**- Bucket Policy Enforcement:** Implemented the complex S3 bucket policy required for the ELB service principal to write logs—a common "real-world" stumbling block for junior engineers. 
**- Triage Capability:** These logs capture client IPs, request paths, user agents, and backend latency, providing the "incident response fuel" needed to debug 5xx errors or WAF blocks.

## Bonus-D Verification (CLI)
The following steps confirm the "Front Gate" is open and the "Flight Recorder" is active:

### 1. Verify Apex Record
aws route53 list-resource-record-sets --hosted-zone-id <ZONE_ID> --query "ResourceRecordSets[?Name=='chewbacca-growl.com.']" Expected Output: An A-Record Alias pointing to the ALB DNS name.

### 2. Verify Logging Attributes
aws elbv2 describe-load-balancer-attributes --load-balancer-arn <ALB_ARN> Expected Output: access_logs.s3.enabled = true and the correct bucket name.

### 3. Generate and Audit Traffic
After running curl -I https://chewbacca-growl.com, verify the logs have landed: aws s3 ls s3://<BUCKET_NAME>/<PREFIX>/AWSLogs/<ACCOUNT_ID>/elasticloadbalancing/ --recursive | head

Access logs allow you to answer the three most important questions during an outage:

Who is hitting us? (Client IP/User Agent)

What are they hitting? (Path/Target)

Where is it breaking? (Response Code/Target Processing Time)

Combined with WAF Logs and ALB 5xx Alarms, you now have a 360-degree view of your application's health.

## Executive Summary: The Ultimate Monolith
With the completion of the Lab 1C suite through Bonus-D, you have delivered a production-grade infrastructure that is:
Encrypted: (TLS 1.3 via ACM)

Shielded: (WAF + Private Subnets)

Isolated: (VPC Endpoints + No Public IPs)

Audited: (ALB Access Logs in S3)

Resilient: (Multi-AZ ASG + Proactive Alarms)

# Lab 1C Bonus-E: WAF Intelligence (Logging & Traffic Analysis)
## Design Goals: Security Observability
The objective of Bonus-E is to capture the "Fingerprints" of every request reaching the application edge. While the WAF blocks malicious traffic, WAF Logging allows for forensic analysis, false-positive tuning, and real-time threat detection.
### 1. Flexible Log Destinations
**- Destination-First Logic:** Implemented a modular logging configuration using aws_wafv2_web_acl_logging_configuration. The stack supports three enterprise-standard destinations via Terraform toggles:

CloudWatch Logs: Optimized for fast, real-time searching and Metric Filter alerting.
S3: Cost-effective, long-term archival for regulatory compliance.
Kinesis Data Firehose: Streaming delivery to SIEM platforms (like Splunk or ELK) for advanced security analytics.

**- Naming Compliance:** Adhered to the strict AWS requirement that all WAF log destinations (Log Groups or Firehose streams) must be prefixed with aws-waf-logs- to be recognized by the WAF service.

### 2. Forensic Triage Capabilities
With WAF logging active, the "Dark VPC" is no longer blind to external threats. We can now answer mission-critical incident response questions:

**- Attack vs. Failure:** "Are the current 5xx errors caused by a backend crash or a surge of blocked requests at the edge?"
**- Pattern Recognition:** "Are we seeing a spike in blocks from a specific IP, ASN, or country code?"
**- Mitigation Audit:** "Did the WAF successfully mitigate the SQL injection attempt, or did it pass through to the database?"

## Bonus-E Verification (CLI)
The following commands confirm that the "Security Guard" is recording every interaction:

### 1. Confirm WAF Logging Configuration
aws wafv2 get-logging-configuration --resource-arn <WEB_ACL_ARN> Expected Output: LogDestinationConfigs contains exactly one valid ARN.

### 2. Verify Log Delivery (CloudWatch Example)
aws logs describe-log-streams --log-group-name aws-waf-logs-chewbacca-webacl01 --order-by LastEventTime --descending aws logs filter-log-events --log-group-name aws-waf-logs-chewbacca-webacl01 --max-items 20

### 3. Verify Log Delivery (S3/Firehose Example)
aws s3 ls s3://aws-waf-logs-chewbacca-<account_id>/ --recursive | head

## Career Point: Incident Response Mastery
WAF logging is the primary source of truth for Security Operations Center (SOC) teams. By providing a searchable log destination, you have enabled:

**False Positive Identification:** Quickly finding and whitelisting legitimate traffic that was accidentally blocked.

**SIEM Integration:** Demonstrating the ability to pipe security events into a larger corporate security ecosystem via Kinesis Firehose.

**Compliance Auditing:** Meeting the standard "Log everything, protect everything" requirement of modern security frameworks.

## Final Project Status: The Complete Production Stack
With Bonus-E complete, my Lab 1C portfolio now represents the pinnacle of AWS Web Architecture:
**Isolated Infrastructure:** (Private Subnets, VPC Endpoints, No SSH)

**Hardened Secrets:** (Secrets Manager, SSM Parameter Store)

**Encrypted Ingress:** (ACM TLS 1.3, Route 53 DNS Validation)

**Layer 7 Defense:** (WAF + Comprehensive WAF Logging)

**Multi-Tier Observability:** (ALB Access Logs, 5xx Alarms, CloudWatch Dashboards)

## Architecture Notes
Implementation of a Hardened, Zero-Trust, Self-Observing Infrastructure. 
Following Best Practices

## Considerations
- Reduction of Security Surface Area by leveraging IAM roles and VPC Endpoints.
- IaC in terraform deployement ensures 100% repeatability and eliminates "Configuration Drift. 
- linking WAF logs, ALB logs, and CloudWatch alarms,provides monitoring and troubleshooting capacities