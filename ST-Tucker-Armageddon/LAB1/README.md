# LAB-1 Series --- Secure EC2 → RDS Operations with Terraform

## Purpose

LAB-1 is a progressive three-part lab series focused on deploying and
operating a secure **EC2 → RDS** workload in AWS using Terraform.

The series moves from foundational infrastructure deployment, to
monitoring and incident response, to automation, recovery, and
operational hardening.

Each lab builds on the previous one, while keeping each lab directory
self-contained for repeatable deployments and controlled teardown.

------------------------------------------------------------------------

## Learning Objectives

Across the LAB-1 series, practitioners will:

-   Deploy AWS infrastructure using Terraform
-   Implement least-privilege security groups and IAM roles
-   Store secrets using AWS Secrets Manager and Parameter Store
-   Collect application logs with CloudWatch Agent
-   Convert logs into metrics and alarms
-   Trigger and investigate simulated failures
-   Perform remediation without redeploying EC2
-   Treat Terraform state as an operational record
-   Extend baseline designs into resilient patterns
-   Investigate WAF and application activity using CloudWatch Logs
    Insights

------------------------------------------------------------------------

## Repository Layout

LAB-1 content lives under `LAB1/`:

-   `LAB1/lab_1a/` --- baseline infrastructure and secrets
-   `LAB1/lab_1b/` --- monitoring, alarms, and incident workflows
-   `LAB1/lab_1c/` --- automation, hardening, and resilience extensions
-   `LAB1/bonus_labs/` --- optional extensions for Lab 1C (A--F)

------------------------------------------------------------------------

## Lab Progression Overview

### LAB-1A --- Core Infrastructure & Secrets

Deploy:

-   VPC, subnets, routing
-   EC2 application host
-   RDS in private subnets
-   Security groups
-   Secrets Manager / Parameter Store
-   IAM roles

📄 `LAB1/lab_1a/README.md`

------------------------------------------------------------------------

### LAB-1B --- Monitoring & Incident Response

Add:

-   CloudWatch Agent
-   Log metric filters
-   Alarms
-   SNS notifications
-   Failure injection via security group edits
-   Recovery without redeploy

📄 `LAB1/lab_1b/README.md`

------------------------------------------------------------------------

### LAB-1C --- Automation & Resilience

Extend:

-   IAM tightening
-   Automated remediation patterns
-   Secrets rotation (where enabled)
-   HA options and operational hardening
-   Terraform state discipline
-   WAF and logging destinations
-   Incident investigation workflows

📄 `LAB1/lab_1c/README.md`

------------------------------------------------------------------------

## Bonus Labs (Lab 1C Extensions)

Bonus labs live here:

📁 `LAB1/bonus_labs/`

-   `lab_1c_bonus_a/`
-   `lab_1c_bonus_b/`
-   `lab_1c_bonus_c/`
-   `lab_1c_bonus_d/`
-   `lab_1c_bonus_e/`
-   `lab_1c_bonus_f/`

Each bonus lab includes its own README and `deliverables/` guidance for
validation evidence.

------------------------------------------------------------------------

## Architecture

All LAB-1 environments share the same baseline EC2 → RDS architecture.

LAB-1B and LAB-1C layer operational controls and resilience on top of
LAB-1A.

Architecture diagrams live within each lab directory:

-   `LAB1/lab_1a/###ARCHITECTURAL DIAGRAM###`
-   `LAB1/lab_1b/###ARCHITECTURAL DIAGRAM###`
-   `LAB1/lab_1c/###ARCHITECTURAL DIAGRAM###`

------------------------------------------------------------------------

## Execution Model

Each lab directory is self-contained and typically follows this
structure:

-   `bootstrap/`
-   `secrets/`
-   `envs/`
-   `modules/`
-   `deliverables/`

General workflow within a lab:

1.  `bootstrap/`
2.  `secrets/`
3.  `envs/` (apply from the active environment folder)

Use **Terraform outputs** as the source of truth for endpoints, log
group names, and resource identifiers.

Destroy environments in reverse order of creation for the specific lab
directory.

------------------------------------------------------------------------

## Prerequisites

-   AWS account
-   AWS CLI configured
-   Terraform installed
-   SNS-capable email address
-   Linux CLI familiarity

------------------------------------------------------------------------

## Cost Notice

⚠️ These labs create AWS resources that may incur charges.

Destroy infrastructure when finished.

------------------------------------------------------------------------

## Deliverables

Each lab and bonus lab maintains local evidence under its
`deliverables/` directory. Typical evidence includes:

-   Terraform outputs captured for key resources
-   CLI verification commands and results
-   Screenshots for console-only confirmations (where required)
-   Notes for incident-style investigations and recovery validation

------------------------------------------------------------------------

## Operating Principles

-   Prefer Terraform-managed changes over console edits
-   Terraform state is treated as an operational artifact
-   Secret rotation may be toggled via variables depending on the lab
-   Validation is performed using Terraform outputs and AWS CLI queries
-   Each lab must support clean teardown using its documented procedures

------------------------------------------------------------------------

## Deployment and Teardown

Procedures for deploying and destroying infrastructure are documented in
each lab's individual README.

Follow the instructions inside:

-   `LAB1/lab_1a/README.md`
-   `LAB1/lab_1b/README.md`
-   `LAB1/lab_1c/README.md`
-   Bonus lab READMEs under `LAB1/bonus_labs/`

------------------------------------------------------------------------

## Summary

LAB-1 focuses on building, operating, monitoring, and hardening an EC2 →
RDS workload in AWS using Terraform, progressing from baseline
infrastructure through alerting, operational recovery, and investigation
workflows.
