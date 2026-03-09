# Lab 3: Global Medical Data Corridor

## Tokyo (Data Authority) & São Paulo (Compute Spoke)

## Project Overview
&nbsp;&nbsp;&nbsp;&nbsp;This project implements a cross-region, multi-state AWS architecture designed for APPI (Act on the Protection of Personal Information) compliance. The architecture ensures that sensitive patient medical records (PHI) remain localized in the Tokyo (ap-northeast-1) region, while providing low-latency compute access for clinicians in São Paulo (sa-east-1).

## Architecture Design
&nbsp;&nbsp;&nbsp;&nbsp;The infrastructure is split into two independent Terraform states to maintain regional sovereignty and operational decoupling.

### 1. Tokyo Hub (ap-northeast-1)
**- Data Authority:** Hosts the primary MariaDB/MySQL RDS instance.

**- Global Services:** Manages the Route 53 Hosted Zone and CloudFront configuration.

**- Connectivity:** Acts as the Transit Gateway (TGW) Hub.

**- Security:** Enforces strict inbound rules allowing only authenticated Spoke traffic via the TGW.

### 2. São Paulo Spoke (sa-east-1)

**- Stateless Compute:** Hosts the Auto Scaling Group (ASG) for the application tier.

**- Network:** Uses a local NAT Gateway for secure egress (SSM access) while routing all database traffic through the TGW.

**- Handshake:** Dynamically discovers the Tokyo environment using Terraform Remote State.

## DevOps Workflow (Multi-State)
&nbsp;&nbsp;&nbsp;&nbsp;This project utilizes a decentralized deployment model. The São Paulo environment is dependent on the outputs of the Tokyo environment.

### Deployment Sequence
 - Tokyo Apply: Deploys the RDS and TGW Hub. Exports tgw_id, vpc_cidr, and rds_endpoint.

 - São Paulo Apply: * Reads Tokyo's remote state.

 - Initiates a Transit Gateway Peering Attachment.

 - Accepts the peering request using a cross-region provider (aws.tokyo).

 - Injects the Tokyo RDS endpoint into the local EC2 user data.

 - Tokyo Return Route: A final apply in Tokyo establishes the return route for the 10.102.0.0/16 CIDR via the TGW Peering link.

## Security & Compliance

**Private Backbone:** Cross-region traffic travels over the AWS global fiber backbone via TGW Peering, never touching the public internet.

**Identity Management:** Instances in Brazil use an IAM Instance Profile (SSM) defined and managed by the Tokyo Data Authority.

**Encrypted Tunnel:** All database connections are restricted to the private 3306 port over the TGW.

## Verification
Connectivity can be verified from any São Paulo instance using the following command:

**Verify the private 'Data Corridor' to Tokyo**

'nc -zv <tokyo_rds_endpoint> 3306'

Expected Output: Connection to ... 3306 port [tcp/mysql] succeeded!

## Repository Structure

├── tokyo/ 
│   ├── 3b_cloudtrail.tf    
│   ├── 3b_tokyo_logs.tf
│   ├── 3b_waf_logging.tf
│   ├── cloudfront.tf                 
│   ├── tokyo_alb.tf        
│   ├── tokyo_asg.tf
│   ├── tokyo_dns.tf
│   ├── tokyo_network.tf
│   ├── tokyo_outputs.tf
│   ├── tokyo_provider.tf
│   ├── tokyo_rds.tf
│   ├── tokyo_routes.tf
│   ├── tokyo_tgw.tf
│   └── tokyo_variables.tf        
└── saopaulo/             
    ├── sao_paulo_alb.tf          
    ├── sao_paulo_asg.tf
    ├── sao_paulo_data.tf
    ├── sao_paulo_dns.tf
    ├── sao_paulo_network.tf
    ├── sao_paulo_outputs.tf
    ├── sao_paulo_provider.tf 
    ├── sao_paulo_routes.tf
    └── sao_paulo_tgw.tf


    Lab 3 implements a **hub-and-spoke multi-region architecture** between **Tokyo (ap-northeast-1)** and **São Paulo (sa-east-1)** with strict **data residency compliance**. Medical data (PHI) must remain exclusively in Tokyo, while São Paulo hosts stateless compute resources.

## Architecture

```
Tokyo (ap-northeast-1)          São Paulo (sa-east-1)
    TGW (shinjuku-tgw) <-- Peering --> TGW (liberdade-tgw)
        |                                   |
    VPC Attachment                    VPC Attachment
        |                                   |
    Tokyo VPC                        São Paulo VPC
        |                                   |
    RDS (MySQL)                      EC2 (Stateless App)
```

## Data Flow Architecture
&nbsp;&nbsp;&nbsp;&nbsp;The following flow describes how a request is handled when a doctor in São Paulo accesses the application:
**- User Entry:** The user hits the CloudFront URL (Global).
**- Traffic Routing:** CloudFront routes the request to the São Paulo Application Load Balancer.
**- Compute:** A Liberdade EC2 instance processes the request.
**- Database Query:** The application needs patient data. It looks up the Tokyo RDS Endpoint (injected via Remote State).
**- Outbound Routing:** The packet hits the São Paulo VPC Route Table $\rightarrow$ directed to the São Paulo TGW.
**- TGW Transit:** The São Paulo TGW Route Table sees the Tokyo CIDR $\rightarrow$ directed to the Peering Attachment.
**- Regional Jump:** The packet travels across the AWS Global Backbone to Japan. 
**- Inbound Routing:** The Tokyo TGW receives the packet $\rightarrow$ directed to the Tokyo VPC Attachment.
**- Handshake:** The Tokyo RDS Security Group validates the São Paulo CIDR and allows port 3306.
**- Return Path:** The process reverses, using the Tokyo TGW Static Route to find its way back to the Brazil CIDR.
    
## Troubleshooting & Resolution Log
&nbsp;&nbsp;&nbsp;&nbsp;During the transition from a monolithic state to a Multi-State Hub-and-Spoke model, the following architectural hurdles were resolved:
    
### 1. The "Undeclared Resource" Error (The State Wall)

**Issue:** After splitting files, São Paulo tried to reference aws_ec2_transit_gateway.liberdade_tgw01.id directly.
    
**Cause:** Terraform cannot see resources in other folders/states natively.
    
**Resolution:** Implemented data.terraform_remote_state to import Tokyo's outputs into the São Paulo environment.
    
### 2. S3 Bucket Conflict (409 Conflict)

**Issue:** Tokyo failed to apply because the Audit Log bucket already existed in AWS.
    
**Cause:** The new Tokyo state file didn't "know" it already owned the bucket created by the previous monolith.
    
**Resolution:** Performed a terraform import aws_s3_bucket.audit_log_vault <bucket-name> to bring the existing resource under management.

### 3. SSM "TargetNotConnected"

**Issue:** EC2 instances in São Paulo private subnets could not be reached via SSM.
    
**Cause:** Private instances lacked a path to the internet to "check-in" with the AWS SSM service.
    
**Resolution:** Deployed an Internet Gateway and NAT Gateway in São Paulo's public subnets and updated the private route tables.

### 4. The Symmetric Routing "Black Hole"

**Issue:** nc -zv to the RDS timed out despite having a peering attachment.
    
**Cause:** Asymmetric routing. São Paulo knew how to get to Tokyo, but Tokyo’s TGW didn't have a static route to send the return packet back to the São Paulo CIDR.
    
**Resolution:** Added a static route in the Tokyo TGW Route Table specifically pointing to the Peering Attachment for the São Paulo CIDR (10.102.0.0/16).

## Monitoring & Global Observability (Day 2 Operations)
&nbsp;&nbsp;&nbsp;&nbsp;To ensure the 11,000-mile "Data Corridor" remains operational, the following cloud-native monitoring was implemented:

### CloudWatch Synthetics: 
&nbsp;&nbsp;&nbsp;&nbsp;Canaries are configured to perform heartbeat "SQL Select" queries from the São Paulo subnet to the Tokyo RDS endpoint, alerting on latency spikes or peering disconnects.

### VPC Flow Logs: 
&nbsp;&nbsp;&nbsp;&nbsp;Enabled on both Transit Gateway attachments to audit cross-region traffic patterns and detect unauthorized access attempts.

### Health Checks: 
&nbsp;&nbsp;&nbsp;&nbsp;Route 53 latency-based routing combined with ALB health checks ensures that if the Brazil application tier becomes unreachable, global traffic is rerouted or throttled to protect data integrity.

##  Teardown & Lifecycle Management
&nbsp;&nbsp;&nbsp;&nbsp;In a Multi-State architecture, dependencies create a "Last One Out" challenge. Because the Tokyo Hub and São Paulo Spoke are geographically and logically linked, destruction must be handled in a specific sequence to avoid orphaned resources or state-lock errors.

##  The Destruction Sequence
&nbsp;&nbsp;&nbsp;&nbsp;To decommission this environment, the "Spoke" must always be removed before the "Hub":

### - Phase 1: São Paulo (The Spoke): 
&nbsp;&nbsp;&nbsp;&nbsp;Run terraform destroy in the saopaulo/ directory. This removes the ASG, the local TGW, and the Peering Attachment.

### - Phase 2: Tokyo Dependency Break: 
&nbsp;&nbsp;&nbsp;&nbsp;Because the Tokyo code references the (now empty) São Paulo state file, the tgw_peering_id output disappears. Before destroying Tokyo, the aws_ec2_transit_gateway_route pointing back to Brazil must be commented out or ignored to prevent Unsupported attribute errors.

### - Phase 3: Tokyo (The Hub): 
&nbsp;&nbsp;&nbsp;&nbsp;Run terraform destroy in the tokyo/ directory to remove the RDS Authority, the Hub TGW, and the Global DNS records.

## Teardown Best Practices
**State Integrity:** Never delete a state file manually before running a destroy; otherwise, you will leave "Zombie" resources running in AWS that Terraform can no longer see.

## Targeted Destruction: 
If a remote state dependency blocks a full destroy, use -target flags (e.g., terraform destroy -target=aws_vpc.main) to remove core resources first.

## Orphaned Volumes: 
Always check the EC2 console for unattached EBS volumes or orphaned Elastic IPs (EIPs) after a destroy, as these can continue to incur costs.

## Interview Presentation: "The Global Medical Data Corridor"

### 1. The Challenge (The "Hook")
"I was tasked with building a high-availability medical application that needed to serve users in South America (São Paulo) while keeping all sensitive patient data (PHI) strictly within Japan (Tokyo) to comply with APPI privacy laws. The technical challenge was creating a seamless 'Data Corridor' across 11,000 miles without using the public internet for database traffic."

### 2. The Solution (The "Meat")
"I architected a Hub-and-Spoke model using Multi-State Terraform.

**- Tokyo (The Hub):** Acted as the 'Data Authority,' hosting the RDS MariaDB instance and the primary DNS/Identity management.

**- São Paulo (The Spoke):** Hosted a stateless application tier that consumed Tokyo’s resources.

**- Connectivity:** I implemented Transit Gateway (TGW) Peering. This allowed the São Paulo compute tier to query the Tokyo database over the private AWS backbone."

### 3. Technical Hurdle & Resolution (The "Expertise")
"One significant challenge was Symmetric Routing. Initially, traffic could reach Japan, but the return packets were being dropped. I resolved this by implementing static routes in the Tokyo Transit Gateway Route Table, ensuring the Hub knew exactly how to route traffic back to the Brazil CIDR across the peering attachment."

### 4. The Result (The "Proof")
"The final build was verified with cross-region network testing. I proved that the 'Stateless' Spoke in Brazil could successfully perform a 3-way handshake with the Tokyo RDS on port 3306, while maintaining a separate local egress path via NAT Gateways for secure SSM management."

## Potential Interview Questions (and how to answer)
 
**- "Why did you split the Terraform into two different state files instead of one big one?"**

&nbsp;&nbsp;&nbsp;&nbsp;"Decoupling. If I want to update the application scaling logic in Brazil, I shouldn't have to risk touching the state of the production database in Japan. It also allows for regional team autonomy and prevents the 'blast radius' of a state file corruption from taking down the entire global infrastructure."

**- "If the TGW Peering link goes down, what happens to the São Paulo users?"**

&nbsp;&nbsp;&nbsp;&nbsp;"Since this is a 'Stateless Spoke' model designed for compliance, the app would fail gracefully. Because we cannot store data locally in Brazil due to APPI laws, no data is at risk. I would implement health checks in Route 53 to failover or show a 'Maintenance' page if the cross-region latency or connectivity exceeds a certain threshold."

**- "Why use a NAT Gateway in São Paulo if the instances are talking to Tokyo via the TGW?"**

&nbsp;&nbsp;&nbsp;&nbsp;"Separation of concerns. The TGW is for private internal traffic (RDS). The NAT Gateway is for public egress. This allows the instances to reach the AWS SSM service for management and download security patches without opening the VPC to inbound internet traffic."

**- "How did you handle the 'Chicken and Egg' problem of the TGW Peering (where both sides need info from the other)?"**

&nbsp;&nbsp;&nbsp;&nbsp;"I used an iterative deployment with terraform_remote_state. I deployed the Hub first, then the Spoke (which initiated the peering and accepted it), and then performed a final 'refresh' apply on the Hub to establish the return routes once the peering ID was generated by the Spoke."

## Business Value & Real-World Use Cases
&nbsp;&nbsp;&nbsp;&nbsp;While this lab focused on medical data, the Hub-and-Spoke / Data Authority model is a standard architectural pattern for global enterprises. This specific setup solves several common business problems:

### 1. Financial Services & FinTech (Data Localization)
Many countries (like Germany or India) require financial transaction data to stay within national borders.

**Application:** A banking app can have a "Compute Spoke" in London for fast UI response, but the "Data Authority" (Hub) remains in Frankfurt to comply with EU banking regulations.

### 2. Global E-Commerce (Inventory Synchronization)
A global retailer needs a "Single Source of Truth" for inventory to prevent overselling.

**Application:** Regional storefronts in the US, Europe, and Asia act as Spokes, but they all query a centralized "Inventory Hub" in Virginia (us-east-1) via TGW Peering. This ensures that when the last item is sold in Tokyo, the New York site reflects "Out of Stock" instantly.

### 3. Media & Entertainment (Post-Production Pipelines)
Studios often have "Render Farms" in regions with lower electricity or spot-instance costs, but keep the "Master Footage" in a secure, central vault.

**Application:** Large video files stay in a central S3/RDS Hub in Los Angeles, while high-compute render tasks are farmed out to a "Spoke" in a cheaper region like Ohio (us-east-2), using the TGW "Data Corridor" to fetch assets privately.

### 4. Mergers & Acquisitions (Secure VPC Integration)
When a large company buys a smaller one, they often need to connect two completely different AWS accounts and networks quickly and securely.

**Application:** This Multi-State TGW Peering model allows the parent company to "Spoke" the newly acquired company’s VPC into their "Hub" without merging the entire infrastructure, maintaining security boundaries while allowing cross-database communication.

## Executive Summary: Why This Matters
For a business, this architecture provides:

**Risk Mitigation:** By centralizing data, you reduce the surface area for data breaches.

**Operational Efficiency:** Managing one database is cheaper and less error-prone than managing ten regional replicas.

**Agility:** New regional "Spokes" can be deployed in minutes by simply replicating the saopaulo/ Terraform code and adjusting the region variables.
