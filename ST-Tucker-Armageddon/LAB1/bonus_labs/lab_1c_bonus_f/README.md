Lab 1C – Bonus F: CloudWatch Logs Insights Investigation Guide
Table of Contents

    Introduction

    Variables Used in This Runbook

    Scope of This Bonus

    Log Source Summary
## Pre-Incident Traffic Generation

Before running any queries, generate baseline application and WAF traffic so that log data exists for analysis.

From a terminal on your workstation:

```bash
for i in {1..30}; do
  curl -s -o /dev/null -w "%{http_code}\n" https://app.devlab405.click/list
  sleep 2
done
```

To simulate common scanner paths (useful for WAF query A6/A7):

```bash
for path in wp-login .env admin phpmyadmin .git login; do
  for i in {1..5}; do
    curl -s -o /dev/null "https://app.devlab405.click/$path"
    sleep 1
  done
done
```

---

    A) WAF Queries

    B) App Queries

    C) Correlation Workflow

    Common Pitfalls

    Troubleshooting Tips

    Practitioner Outcome

    Closing Summary

Introduction

Bonus F shifts Lab‑1C from simply deploying infrastructure to actively operating it like real cloud engineers. Instead of only provisioning resources, practitioners learn how to investigate live issues using CloudWatch Logs Insights, CloudWatch metrics, and AWS WAF logs.

This bonus teaches practitioners how to:

    Interpret WAF logs

    Analyze application logs under pressure

    Correlate CloudWatch alarms with real log evidence

    Separate attacker traffic from backend failures

    Build a timeline of events during an incident

    Justify remediation actions with data

By completing this bonus, operators practice real-world troubleshooting, identify malicious traffic, and confirm recovery using AWS-native tools.
Variables Used in This Runbook

Replace the example values below with the actual log group names from the environment.
Item	Example Value	Description
WAF log group	aws-waf-logs-lab-1c-webacl	WAF logs delivered to CloudWatch Logs
App log group	/aws/ec2/lab-1c-rds-app	Application logs from the EC2 instance
Time Range Requirement

CloudWatch Logs Insights should always be set to:

Last 15 minutes  
(or match the specific incident window)
Scope of This Bonus

CloudWatch Logs Insights can only query logs stored in CloudWatch Logs.
Included

    AWS WAF logs (when waf_log_destination = "cloudwatch")

    Application logs in /aws/ec2/<prefix>-rds-app

Not Included

    ALB access logs (stored in S3 unless shipped to CloudWatch)

ALB Correlation Uses

    CloudWatch metrics

    ALB 5xx alarms

    Athena (later in the course)

Log Source Summary
Log Type	Location	Included?	Notes
WAF logs	CloudWatch Logs	Yes	Used for attack analysis
App logs	/aws/ec2/...	Yes	Used for backend failure correlation
ALB access logs	S3	No	Queried later via Athena
A) WAF Queries

These queries help determine whether an issue is caused by attackers, scanners, or normal traffic.
A1 — What’s happening right now? (Top actions)
sql

fields @timestamp, action
| stats count() as hits by action
| sort hits desc

A2 — Top client IPs
sql

fields @timestamp, httpRequest.clientIp as clientIp
| stats count() as hits by clientIp
| sort hits desc
| limit 25

A3 — Top requested URIs
sql

fields @timestamp, httpRequest.uri as uri
| stats count() as hits by uri
| sort hits desc
| limit 25

A4 — Blocked requests only
sql

fields @timestamp, action, httpRequest.clientIp as clientIp, httpRequest.uri as uri
| filter action = "BLOCK"
| stats count() as blocks by clientIp, uri
| sort blocks desc
| limit 25

A5 — Which WAF rule is blocking traffic?
sql

fields @timestamp, action, terminatingRuleId, terminatingRuleType
| filter action = "BLOCK"
| stats count() as blocks by terminatingRuleId, terminatingRuleType
| sort blocks desc
| limit 25

A6 — Rate of blocks over time (pattern-based)
sql

fields @timestamp, httpRequest.clientIp as clientIp, httpRequest.uri as uri
| filter uri =~ /wp-login|xmlrpc|\.env|admin|phpmyadmin|\.git|login/
| stats count() as hits by clientIp, uri
| sort hits desc
| limit 50

A7 — Suspicious scanners (common attack paths)
sql

fields @timestamp, httpRequest.clientIp as clientIp, httpRequest.uri as uri
| filter uri =~ /wp-login|xmlrpc|\.env|admin|phpmyadmin|\.git|login/
| stats count() as hits by clientIp, uri
| sort hits desc
| limit 50

A8 — Country/geo breakdown (if present)
sql

fields @timestamp, httpRequest.country as country
| stats count() as hits by country
| sort hits desc
| limit 25

B) App Queries

These queries help determine whether an issue is caused by backend failures, credentials drift, or network problems.
B1 — Count errors over time
sql

fields @timestamp, @message
| filter @message like /ERROR|Exception|Traceback|DB|timeout|refused/i
| stats count() as errors by bin(1m)
| sort bin(1m) asc

B2 — Most recent DB failures
sql

fields @timestamp, @message
| filter @message like /DB|mysql|timeout|refused|Access denied|could not connect/i
| sort @timestamp desc
| limit 50

B3 — “Is it creds or network?” classifier
sql

fields @timestamp, @message
| filter @message like /Access denied|authentication failed|timeout|refused|no route|could not connect/i
| stats count() as hits by
  case(
    @message like /Access denied|authentication failed/i, "Creds/Auth",
    @message like /timeout|no route/i, "Network/Route",
    @message like /refused/i, "Port/SG/ServiceRefused",
    "Other"
  )
| sort hits desc

B4 — Structured JSON logs (if the application emits JSON)
sql

fields @timestamp, level, event, reason
| filter level="ERROR"
| stats count() as n by event, reason
| sort n desc

C) Correlation Workflow

This workflow is designed for inclusion in the incident runbook.
Step 1 — Confirm signal timing

    Review the CloudWatch alarm window (last 5–15 minutes)

    Run App B1 to confirm error spike timing

Step 2 — Decide: Attack or Backend Failure

Run:

    WAF A1 (top actions)

    WAF A6 (scanner patterns)

If BLOCK spikes align with the incident:  
→ Likely external pressure or scanning

If WAF is quiet but app errors spike:  
→ Likely backend issue (RDS, SG, credentials, network)
Step 3 — If backend failure is suspected

Run App B2 and B3:

    Access denied → credentials drift / incorrect password

    timeout / no route → SG, routing, or RDS availability issue

    refused → port/SG/service not listening

Retrieve known‑good values from:

    Parameter Store: /lab/db/*

    Secrets Manager: /<prefix>/rds/mysql

Step 4 — Verify recovery

    Application errors return to baseline (B1)

    WAF blocks stabilize (A6)

    CloudWatch alarm returns to OK

    Application endpoint responds normally

Common Pitfalls

    Forgetting to set the time range

    Using incorrect log group names

    Expecting ALB logs in CloudWatch

    Not filtering out noise (health checks, bots)

    Assuming all 5xx errors are attacks

Troubleshooting Tips

    No logs? Check IAM permissions and log group names

    Missing WAF logs? Ensure WAF logging is enabled

    Empty app logs? Verify CloudWatch agent or Fluent Bit

    Too much data? Add filters (IP, URI, rule ID, keywords)

Practitioner Outcome

After completing Bonus F, practitioners are able to:
Detection

    Identify abusive IPs and scanning patterns

    Determine which WAF rules are firing

Analysis

    Distinguish attacker traffic from backend failures

    Correlate application errors with network or credential issues

Correlation

    Build a timeline using logs, metrics, and alarms

Reporting

    Confirm service recovery

    Produce evidence‑based incident summaries

Closing Summary

Bonus F transforms Lab‑1C into a fully observable environment. Practitioners learn how to investigate outages, analyze logs, and support alarms with real evidence — the same skills used by cloud operations and SOC teams in real AWS environments.

---

## Terraform Destroy Verification (Bonus F Gate)

After completing investigations and capturing required evidence, destroy the stack:

```bash
terraform destroy
```

Confirm key resources are removed:

```bash
aws secretsmanager describe-secret --region ap-northeast-1 --secret-id "lab-1c/rds/mysql"
aws elbv2 describe-load-balancers --region ap-northeast-1 --names lab-1c-alb
aws rds describe-db-instances --region ap-northeast-1 --db-instance-identifier lab-mysql
aws logs describe-log-groups --region ap-northeast-1 --log-group-name-prefix "aws-waf-logs-lab-1c"
aws wafv2 list-web-acls --region ap-northeast-1 --scope REGIONAL --output table
```

Expected outcomes:

- Secrets Manager returns `ResourceNotFoundException`
- ALB returns `LoadBalancerNotFound`
- RDS returns `DBInstanceNotFound`
- WAF log groups list is empty
- WAF Web ACL list is empty

