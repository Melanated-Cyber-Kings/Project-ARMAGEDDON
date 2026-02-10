# Lab-1C --- Bonus E

## AWS WAF Logging, Enforcement, and Incident Correlation

------------------------------------------------------------------------

## Overview

Bonus E builds on the Lab-1C environment and focuses on how a real AWS
ingress security layer operates. Instead of running only a basic
two-tier application, this stage adds edge protection, telemetry, and
investigation workflows commonly encountered in enterprise cloud
environments.

At this point in the lab, the environment includes:

-   Private RDS databases\
-   EC2 application hosts with IAM roles\
-   Secrets Manager with rotation Lambdas\
-   CloudWatch alarms and dashboards\
-   SNS notifications\
-   Application Load Balancers with TLS\
-   Route53 DNS\
-   VPC endpoints for restricted AWS API access\
-   AWS WAF in front of all internet traffic

Bonus E focuses on ensuring that every request entering the environment
is:

-   inspected by AWS WAF\
-   evaluated by managed rule groups\
-   allowed or blocked\
-   logged centrally\
-   searchable via CLI\
-   correlated with ALB, EC2, and RDS behavior

The goal is not simply to enable logging --- but to demonstrate that the
environment supports operational security workflows such as:

-   distinguishing attacks from application failures\
-   verifying whether WAF blocked requests before they reached EC2 or
    RDS\
-   identifying abusive IP addresses, countries, and paths\
-   correlating attack spikes with ALB 5xx alarms\
-   performing basic forensics using CloudWatch Logs or S3\
-   supporting SOC-style triage

By completing Bonus E, the Lab-1C stack behaves like a real enterprise
ingress tier where controls are:

-   enforceable\
-   observable\
-   auditable\
-   useful during incidents

------------------------------------------------------------------------
📘 Operations Runbook

This runbook is what I follow whenever I deploy, troubleshoot, or tear down the Bonus E environment. 
It helps me keep the order straight, avoid common mistakes, and work through issues the same way an 
operator would in a real AWS setup.

To keep things organized, the runbook covers three main areas:
🔧 Deployment & Lifecycle

    exact deployment order

    Secrets Manager rotation toggling

    safe teardown sequencing

    redeploy and recovery scenarios

🛠️ Validation & Troubleshooting

    AWS WAF CLI validation

    CloudWatch pagination and log forensics

    S3 / Firehose logging alternatives

📦 Grading & Artifacts

    grading gate script execution

    artifact collection

    containerized grading workflows

The full step‑by‑step procedures live in OPERATIONS.m, which I use as my reference during hands‑on work. 
It focuses on the operational tasks only — not the Terraform code or architecture deep dives — so it’s easy 
to follow when I’m actually running the environment.

------------------------------------------------------------------------

## Architecture Focus

Bonus E centers on the ingress path:

    Internet → Route53 → ACM TLS → ALB → WAF Web ACL → EC2 App Tier → RDS

WAF logging is configured in Terraform. Each Web ACL can emit logs to
exactly one destination:

-   CloudWatch Logs\
-   S3\
-   Kinesis Data Firehose

The destination is selected using variables in the ingress module.

------------------------------------------------------------------------

## Repository Locations

### Ingress Module

    modules/ingress/
    ├── waf.tf
    ├── waf_logging.tf
    ├── alb.tf
    ├── listeners.tf
    ├── route53.tf
    ├── outputs.tf
    └── variables.tf

### Environment Wiring

    envs/lab-1c/
    ├── 03-variables.tf
    └── 04-outputs.tf

### Deliverables

    deliverables/
    ├── bonus_e_A_waf_logging_configuration.json
    ├── bonus_e_A_log_destination_count.txt
    ├── bonus_e_B_curl_apex_headers.txt
    ├── bonus_e_B_curl_app_headers.txt
    ├── bonus_e_C1_filter_log_events_*.json
    ├── gate_secrets_and_role_ec2.txt
    ├── gate_network_db_workstation.txt
    └── screenshots/

------------------------------------------------------------------------

## Deployment Workflow

Lab-1C uses Secrets Manager with optional rotation Lambdas. The
deployment order matters:

1.  Deploy `secrets/` with rotation disabled\
2.  Deploy `envs/lab-1c/`\
3.  Update secrets with the real RDS endpoint\
4.  Enable rotation after the Lambda exists\
5.  Disable rotation again before destroying the environment

------------------------------------------------------------------------

## Rotation Lambda Toggle (Important)

Rotation Lambdas frequently prevent clean teardown.

Before first deploy:

    rotation_lambda_arn = ""
    rotation_days       = 30

After environment deploy:

    rotation_lambda_arn = "arn:aws:lambda:REGION:ACCOUNT:function:lab-1c-rds-rotation-mysql"
    rotation_days       = 30

Before teardown, comment these again and re-apply.

------------------------------------------------------------------------

## Bonus E Validation (CLI)

### A) Confirm WAF Logging Is Enabled

    aws wafv2 get-logging-configuration   --resource-arn <WEB_ACL_ARN>

Expected:

-   `LogDestinationConfigs` contains exactly one destination.

Artifacts:

-   `bonus_e_A_waf_logging_configuration.json`\
-   `bonus_e_A_log_destination_count.txt`

------------------------------------------------------------------------

### B) Generate Traffic

    curl -I https://example.com/
    curl -I https://app.example.com/

Artifacts:

-   `bonus_e_B_curl_apex_headers.txt`\
-   `bonus_e_B_curl_app_headers.txt`

------------------------------------------------------------------------

### C) Validate CloudWatch WAF Logs

    aws logs describe-log-streams   --log-group-name aws-waf-logs-lab-1c-webacl   --order-by LastEventTime --descending

    aws logs filter-log-events   --log-group-name aws-waf-logs-lab-1c-webacl   --max-items 20

Artifacts:

-   `bonus_e_C1_filter_log_events_*.json`

------------------------------------------------------------------------

## Blocked Request Evidence

WAF logs must show enforcement:

-   `action = BLOCK`\
-   `terminatingRuleId = AWSManagedRulesCommonRuleSet`\
-   `ruleId = NoUserAgent_HEADER`\
-   `httpSourceName = ALB`\
-   client IP and country\
-   host and URI

This confirms:

-   managed rules are enforcing\
-   ALB is the protected ingress\
-   attribution is preserved\
-   requests are stopped before reaching EC2

------------------------------------------------------------------------

## Why This Matters

WAF telemetry allows operators to:

-   correlate WAF spikes with ALB 5xx alarms\
-   determine whether outages are attack-driven or application failures\
-   investigate abusive IPs and regions\
-   identify targeted endpoints\
-   validate that mitigations are effective\
-   reconstruct timelines during incidents

These workflows mirror real-world SOC and cloud operations practices.
