# Armageddon Labs --- Multi‑Stage AWS Security & Operations Curriculum

This repository contains a progressive, scenario‑driven series of labs
focused on building, securing, operating, and extending production‑grade
AWS environments using Terraform.

The labs are grouped into **three major tracks**:

-   **LAB‑1** --- Secure EC2 → RDS foundations and incident response\
-   **LAB‑2** --- CloudFront ingress protection and CDN correctness\
-   **LAB‑3** --- Multi‑region regulated healthcare architecture

Each track builds on the previous work and mirrors real enterprise
design patterns.

------------------------------------------------------------------------

# LAB‑1 --- Secure EC2 → RDS Operations

LAB‑1 introduces secure single‑region workloads and operational
visibility.

## LAB‑1A --- Core Infrastructure & Secrets

Deploy:

-   VPC, routing, NAT
-   EC2 application host
-   RDS in private subnets
-   Security groups
-   Secrets Manager / Parameter Store
-   IAM roles

Focus:

-   reproducible builds
-   least privilege
-   secure networking
-   Terraform workflow discipline

------------------------------------------------------------------------

## LAB‑1B --- Monitoring & Incident Response

Add:

-   CloudWatch Agent via user‑data
-   Log ingestion
-   Metric filters
-   Alarms
-   SNS notifications
-   Failure simulation by breaking DB access
-   Recovery through configuration, not redeploy

------------------------------------------------------------------------

## LAB‑1C --- Automation & Resilience

Extend:

-   IAM tightening
-   automated remediation patterns
-   secret‑rotation preparation
-   HA options
-   Terraform state governance

------------------------------------------------------------------------

# LAB‑2 --- CloudFront as the Only Public Ingress

LAB‑2 introduces edge security and CDN operational correctness.

## LAB‑2A --- Origin Cloaking with CloudFront

Architecture:

Internet → CloudFront (+ WAF) → ALB → Private EC2 → RDS

Controls introduced:

-   ALB inbound restricted to AWS CloudFront prefix list
-   Secret origin header required by ALB listener
-   WAF moved from ALB to CloudFront
-   Route53 aliases point to CloudFront

Students verify:

-   direct ALB access fails (403)
-   CloudFront access succeeds
-   DNS resolves to CloudFront
-   WAF is attached globally

------------------------------------------------------------------------

## LAB‑2B --- CDN Cache Correctness

Focus:

-   aggressive caching for static assets
-   safe or disabled caching for APIs
-   minimal but correct cache keys
-   origin request policies
-   response headers policies

Students prove:

-   cache hits/misses via headers
-   no auth leakage
-   no stale reads
-   correct forwarding behavior

------------------------------------------------------------------------

# LAB‑3 --- Regulated Global Architecture

LAB‑3 moves into enterprise and compliance‑driven multi‑region design.

## LAB‑3A --- Transit Gateway Between Regions

Scenario:

-   Primary region: Tokyo
-   Satellite region: São Paulo
-   RDS remains only in Tokyo
-   EC2 runs in both regions
-   Transit Gateways in each region are peered

Key topics:

-   TGW peering
-   cross‑region routing
-   security‑group CIDR strategy
-   DNS resolution
-   operational trade‑offs

------------------------------------------------------------------------

## LAB‑3 --- Japan Medical Compliance Scenario

Regulated healthcare architecture enforcing Japan's APPI law.

Constraints:

-   PHI stored only in Tokyo
-   No cross‑region DB replicas
-   São Paulo hosts stateless compute only
-   CloudFront provides global access
-   Transit Gateway carries encrypted DB traffic

Why it matters:

-   translates law into architecture
-   forces asymmetric multi‑region design
-   prepares engineers for audits
-   teaches compliance‑driven trade‑offs

------------------------------------------------------------------------

# Execution Order

Labs should be completed sequentially:

1.  LAB‑1
2.  LAB‑2
3.  LAB‑3

Destroy environments in reverse order.

------------------------------------------------------------------------

# Prerequisites

-   AWS account
-   Terraform installed
-   AWS CLI configured
-   SNS‑capable email
-   Linux CLI familiarity

------------------------------------------------------------------------

# Cost Notice

⚠️ These labs deploy billable AWS resources.

Destroy infrastructure when finished.

------------------------------------------------------------------------

# Summary

This curriculum trains engineers to:

-   deploy secure AWS foundations
-   operate and monitor production systems
-   protect public ingress with CloudFront
-   design correct CDN caching
-   build cross‑region networks
-   translate compliance into architecture

The progression intentionally mirrors how real cloud engineers mature in
industry.
