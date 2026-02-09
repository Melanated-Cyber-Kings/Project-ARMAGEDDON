# Lab 1C — Operating and Recovering an EC2 → RDS Environment with Terraform

## 📋 Lab Overview

Lab-1C builds directly on **Lab-1B**.

The same AWS infrastructure is reused:

- EC2 application host
- RDS MySQL database
- Secrets Manager
- SSM Parameter Store
- CloudWatch Logs and alarms
- SNS notifications

Unlike earlier labs, **no new core services or architecture are introduced**.

Instead, Lab-1C focuses on:

> **Operating the environment as if it were production.**

Users must intentionally break the system, detect the failure through monitoring, follow an incident runbook, recover service, and prove the full Terraform lifecycle from creation to destruction.

---

## 🎯 Objectives

This lab emphasizes operational maturity:

- Infrastructure lifecycle with Terraform
- Symptom-based monitoring
- Alarm-driven incident detection
- Runbook-based recovery
- Mean-time-to-recovery (MTTR) awareness
- Evidence-driven validation

---

## 🧭 How Lab-1C Extends Lab-1B

Lab-1C uses the **same Terraform modules and layout** as Lab-1B.

| Lab | Focus |
|-----|------|
| 1A | Build EC2 → RDS |
| 1B | Add logging and alerts |
| 1C | Operate, break, detect, recover, and document |

---

## 🏗️ Architecture (Same as Lab-1B)

Single-region deployment with:

- Custom VPC
- NAT Gateway
- EC2 app host
- Private RDS
- Secrets Manager
- SSM Parameter Store
- CloudWatch Logs + alarms
- SNS topic

---

## 📁 Repository Structure

```
lab_1c/
├── bootstrap/
├── secrets/
├── envs/lab-1c/
├── modules/
├── deliverables/
└── README.md
```

---

## 🚀 Deployment Process

Follow the same deployment order as Lab-1B:

1. bootstrap
2. secrets
3. envs/lab-1c
4. secrets update
5. validation
6. terraform destroy

---

## 📊 Monitoring Expectations

From Lab-1B:

- Log group: /aws/ec2/lab-rds-app
- Metric filter: DB_CONNECTION_ERROR
- Alarm ≥ 3 errors / 5 min
- SNS notifications

---

## 🧪 Incident Simulation

Break connectivity (for example: RDS SG port change) and confirm:

- logs show errors
- alarm enters ALARM
- SNS delivered
- restore connectivity
- alarm returns OK

---

## 📁 Required Deliverables

### Terraform Lifecycle

- terraform_plan.txt
- terraform_apply.txt
- terraform_outputs.txt
- terraform_destroy.txt

### Operational Evidence

- CLI verification output
- alarm screenshots
- SNS notification
- logs showing errors

### Incident Runbook

- incident_runbook_execution.txt
  - failure injected
  - detection time
  - recovery action
  - MTTR

---

## ✅ Validation of Completion

- [ ] terraform apply works
- [ ] alarm fires
- [ ] SNS delivered
- [ ] runbook executed
- [ ] terraform destroy succeeds

---

## 🔮 Bonus (Optional)

- ASG
- ALB
- dashboards
- CI/CD
