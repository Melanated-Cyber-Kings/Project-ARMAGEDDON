# LAB3 --- Japan Medical Global Architecture & Compliance Validation

APPI-Aligned Multi-Region Design with Transit Gateway & Audit Evidence

## Overview

LAB3 teaches how to design and prove compliance for a regulated,
multi-region medical workload where legal requirements drive
architecture.

This lab is split conceptually into two parts:

-   Lab 3A --- Architecture & Regional Design
-   Lab 3B --- Audit Evidence & Compliance Verification

Together they demonstrate how engineers:

-   Design asymmetric global systems
-   Enforce data-residency laws
-   Create controlled cross-region data corridors
-   Produce audit-ready proof
-   Communicate compliance posture to regulators and auditors

------------------------------------------------------------------------

## Architectural Scenario

Japan's privacy law --- APPI (個人情報保護法) --- requires that medical
PHI belonging to Japanese citizens be stored physically inside Japan.

This applies even when:

-   A patient is traveling
-   A doctor is overseas
-   The application is globally accessible

Access is allowed. Storage is not.

------------------------------------------------------------------------

## Regional Roles

### Tokyo --- Primary Region (Authoritative Data)

Tokyo is the source of truth and contains:

-   RDS medical database
-   Primary VPC
-   Application tier
-   Transit Gateway hub
-   Parameter Store & Secrets Manager
-   Logging, auditing, and backups

All PHI at rest lives here.

If Tokyo becomes unavailable, the system may degrade --- but data
residency is never violated.

------------------------------------------------------------------------

### São Paulo --- Secondary Region (Stateless Compute)

São Paulo reduces latency for South American users and contains:

-   VPC
-   EC2 + Auto Scaling Group
-   Application tier
-   Transit Gateway spoke

It does not contain:

-   RDS
-   Read replicas
-   Backups
-   Any persistent PHI storage

São Paulo is stateless compute. All reads and writes go directly to
Tokyo.

------------------------------------------------------------------------

## Key Architectural Truths

### Compliance

-   PHI storage stays in Tokyo
-   Compute can move
-   Access can be global
-   Storage cannot

### Engineering

-   Transit Gateway creates a controlled corridor
-   CloudFront provides a single global URL
-   São Paulo is stateless
-   Tokyo is authoritative

------------------------------------------------------------------------

## Transit Gateway Design Pattern

Transit Gateway is regional.

Correct regulated-enterprise pattern:

-   TGW in Tokyo
-   TGW in São Paulo
-   TGW Peering Attachment
-   Each VPC attaches to its local TGW
-   Routes propagate across the peering

------------------------------------------------------------------------

## End-to-End Traffic Flow

Doctor in São Paulo\
CloudFront\
São Paulo EC2\
TGW (São Paulo)\
TGW Peering\
TGW (Tokyo)\
Tokyo VPC\
Tokyo RDS

All traffic remains on the AWS backbone and is encrypted.

------------------------------------------------------------------------

## Single Global Entry Point

Only one public URL exists:

https://devlab405.click

CloudFront:

-   Terminates TLS
-   Applies WAF
-   Routes users to the nearest healthy region
-   Never stores PHI
-   Caches only explicitly safe content

------------------------------------------------------------------------

## Terraform & DevOps Structure

### Multi-State Reality

Each region is deployed from a separate Terraform state:

-   Tokyo state
-   São Paulo state

They communicate only through:

-   Remote state references
-   Outputs
-   Explicit variables

------------------------------------------------------------------------

### Expected Repository Layout

    lab-3/
    ├── tokyo/
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    │
    ├── saopaulo/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── data.tf

------------------------------------------------------------------------

## Security Model

-   RDS inbound only from:
    -   Tokyo application subnets
    -   São Paulo VPC CIDR
-   No public DB access
-   No PHI stored outside Tokyo
-   All access logged

This is compliance by design, not policy.

------------------------------------------------------------------------

# LAB3 Audit Evidence Pack

LAB3 requires producing CLI-verifiable proof that the architecture
behaves correctly.

------------------------------------------------------------------------

## Deliverable A --- Audit Pack

    audit-pack/
    ├── 00_architecture-summary.md
    ├── 01_data-residency-proof.txt
    ├── 02_edge-proof-cloudfront.txt
    ├── 03_waf-proof.txt
    ├── 04_cloudtrail-change-proof.txt
    ├── 05_network-corridor-proof.txt
    └── evidence.json

------------------------------------------------------------------------

## Verification Requirements

### Data Residency --- RDS Only in Tokyo

Tokyo:

``` bash
aws rds describe-db-instances \
  --region ap-northeast-1 \
  --query "DBInstances[].{DB:DBInstanceIdentifier,AZ:AvailabilityZone,Region:'ap-northeast-1',Endpoint:Endpoint.Address}"
```

São Paulo:

``` bash
aws rds describe-db-instances \
  --region sa-east-1 \
  --query "DBInstances[].DBInstanceIdentifier"
```

------------------------------------------------------------------------

### CloudFront Edge Proof

``` bash
curl -I https://devlab405.click/api/public-feed
```

Logs:

``` bash
aws s3 ls s3://Class_Lab3/Chwebacca-logs/ --recursive
```

------------------------------------------------------------------------

### WAF Proof

``` bash
aws logs tail /aws/waf/medical_global_waf --since 1h
```

------------------------------------------------------------------------

### CloudTrail Change History

``` bash
aws cloudtrail lookup-events --max-results 20
```

------------------------------------------------------------------------

### TGW Corridor Proof

``` bash
aws ec2 describe-transit-gateway-attachments --region ap-northeast-1
aws ec2 describe-transit-gateway-attachments --region sa-east-1
```

------------------------------------------------------------------------

### S3 Logging Verification

``` bash
aws s3 ls s3://Class_Lab3/
aws s3 ls s3://Class_Lab3/Chwebacca-logs/ --recursive
```

------------------------------------------------------------------------

## Malgus Verification Scripts

Scripts included:

-   malgus_residency_proof.py
-   malgus_tgw_corridor_proof.py
-   malgus_cloudtrail_last_changes.py
-   malgus_waf_summary.py
-   malgus_cloudfront_log_explainer.py

------------------------------------------------------------------------

## Deliverable B --- Auditor Narrative

This architecture ensures APPI compliance by keeping all PHI strictly
within Japan while still enabling global access.

Tokyo hosts the only RDS instance, making it authoritative, while São
Paulo operates as stateless compute that never stores PHI locally.

A Transit Gateway corridor provides a controlled, auditable path between
regions without exposing data to the public internet.

CloudFront provides a single secure entry point worldwide, WAF protects
the edge, CloudTrail records all changes immutably, and S3 stores logs
for forensic analysis.

Together these controls ensure performance, resilience, and legal
compliance.

------------------------------------------------------------------------

## What This Lab Teaches

LAB3 demonstrates how to:

-   Design legally constrained global systems
-   Enforce data residency
-   Build audit-ready architectures
-   Validate behavior through logs
-   Support compliance teams
-   Communicate clearly with auditors
