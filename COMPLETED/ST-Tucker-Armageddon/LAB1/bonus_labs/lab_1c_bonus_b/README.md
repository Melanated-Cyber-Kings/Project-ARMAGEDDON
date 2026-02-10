# Lab 1C --- Bonus B

## Enterprise Ingress: ALB + TLS + WAF + Monitoring

------------------------------------------------------------------------

## Purpose

Bonus-B extends Lab‑1C and Bonus‑A into a production‑style ingress
pattern used by modern organizations:

-   Public Application Load Balancer
-   Private EC2 targets
-   TLS certificates via ACM
-   Route53 DNS automation
-   AWS WAF protection
-   CloudWatch dashboards
-   SNS alarms for ALB 5xx spikes

This layer models real enterprise delivery:

> IaC → Private compute → Managed ingress → TLS → WAF → Monitoring →
> Alerting

------------------------------------------------------------------------

## Architecture Summary

-   ALB deployed in public subnets across AZs\
-   EC2 instances remain private (no public IPs)\
-   HTTPS listener on 443\
-   HTTP redirected to HTTPS\
-   WAF attached to ALB\
-   CloudWatch dashboard and alarm pipeline\
-   Route53 alias record for application hostname

------------------------------------------------------------------------

## Domain Assumptions

This lab assumes control of a public DNS domain.

Example used:

    app.devlab405.click

Replace with your own domain and hosted zone.

------------------------------------------------------------------------

## Repository Layout

Bonus‑B is created by copying Bonus‑A forward and layering ingress
features.

Key files:

    envs/lab-1c/
      └── 06-ingress-alb.tf

    envs/lab-1c/scripts/
      └── bonus_b_validate.sh

    deliverables/
      └── bonus_b_cli_verification.md

------------------------------------------------------------------------

# Deployment Workflow (No S3 Backend)

Unless explicitly enabled, this lab runs with local state using
`-backend=false`.

------------------------------------------------------------------------

## Phase 1 --- Bootstrap

Leave the `bootstrap/` directory unchanged.

No Bonus‑B‑specific modifications are required.

------------------------------------------------------------------------

## Phase 2 --- Secrets Stack

From:

    secrets/

Verify:

-   Secret already exists
-   Rotation Lambda is optional
-   `rotation_lambda_arn` is commented in tfvars unless intentionally
    enabled

Run:

```
terraform init -backend=false
terraform plan
terraform apply
```

------------------------------------------------------------------------

## Phase 3 --- Environment Stack

From:

    envs/lab-1c/

### Update `lab-1c.auto.tfvars`

Confirm or modify:

-   Domain name / subdomain
-   Route53 hosted zone ID
-   Enable ALB / WAF toggles
-   Optional Route53 automation flags
-   Application port
-   Region

Then run:

```
terraform init -backend=false
terraform plan
terraform apply
```

ACM DNS validation may take several minutes.

------------------------------------------------------------------------

# Automated Validation

Bonus‑B includes a validation script that:

-   Pulls Terraform outputs
-   Queries AWS APIs
-   Confirms:
    -   ALB state and listeners
    -   Target group health
    -   WAF attachment
    -   DNS alias record
    -   ACM certificate status
    -   CloudWatch alarm
    -   Dashboard existence
    -   HTTPS redirect

------------------------------------------------------------------------

## Run Validation

```
cd envs/lab-1c

chmod +x scripts/bonus_b_validate.sh

./scripts/bonus_b_validate.sh   --region ap-northeast-1   --zone-id Z103851437PNELROEQ0AM
```

------------------------------------------------------------------------

## Validation Artifacts

Output is written to:

    deliverables/bonus_b_cli_verification.md

This file serves as the formal verification record for the deployment.

------------------------------------------------------------------------

# Operational Notes and Known Pitfalls

The following issues were encountered while evolving this stack:

------------------------------------------------------------------------

## ALB Targets Unhealthy

-   Application not listening on expected port
-   Missing ALB → EC2 security group rule
-   Health‑check path mismatch

Verification:

```
aws elbv2 describe-target-health   --target-group-arn <TG_ARN>
```

------------------------------------------------------------------------

## ACM DNS Validation Issues

-   DNS record created in wrong hosted zone
-   Incorrect FQDN
-   Propagation delays

Verification:

```
aws acm describe-certificate   --certificate-arn <CERT_ARN>
```

------------------------------------------------------------------------

## Terraform Module Output Mismatches

-   Overlay referenced non‑exported module outputs
-   Fixed by adding explicit outputs

------------------------------------------------------------------------

## Secrets Schema Drift

-   `dbname` vs `db_name` mismatch
-   Normalized once in locals

------------------------------------------------------------------------

## ACM Validation Record Indexing Errors

-   Provider returns set
-   Resolved using `for_each`

------------------------------------------------------------------------

## CloudWatch Dashboard Validation Errors

-   Missing region in widget JSON
-   Resolved by explicitly setting region

------------------------------------------------------------------------

## Slow Resource Teardown

-   WAF and Lambda deletion took extended time
-   Completed without manual cleanup

------------------------------------------------------------------------

# Teardown

From:

    envs/lab-1c/

Run:

```
terraform destroy
```

Destroy secrets if required:

```
cd secrets
terraform destroy
```

------------------------------------------------------------------------