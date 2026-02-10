# Lab 1C — Bonus F: CloudWatch Logs Insights Query Pack (Incident Workflow)

## Purpose
Provide a reusable CloudWatch Logs Insights “query pack” to accelerate incident triage and correlation across:

- **AWS WAF logs** (when `waf_log_destination = "cloudwatch"`)
- **Application logs** in CloudWatch Logs (EC2 app log group)

This pack does **not** cover ALB access logs directly (they are stored in S3 unless you build a separate shipping pipeline). For ALB correlation you will use:
- CloudWatch ALB metrics (5xx, target response time, etc.)
- ALB alarms/dashboards (if enabled)
- Optional later enhancement: Athena over ALB access logs in S3

---

## Prerequisites
- Deployment completed successfully (`terraform apply` in `envs/lab-1c`)
- WAF logging configured to CloudWatch:
  - `waf_log_destination = "cloudwatch"`
- Application logs exist in CloudWatch Logs under `/aws/ec2/<prefix>-rds-app`

---

## Variables
Fill these in for your environment before running queries.

### Log Groups
- **WAF log group (CloudWatch):** `aws-waf-logs-lab-1c-webacl`
- **App log group (CloudWatch):** `/aws/ec2/lab-rds-app` *(update if your prefix differs)*

### Time Range
Set the CloudWatch Logs Insights time window to:
- **Last 15 minutes** (recommended for active triage)
- Or match the incident window from the CloudWatch alarm / notification

---

## Pre-Incident Setup and Query Execution

### Traffic Generation
Before running any queries, generate baseline application and WAF traffic so that log data exists for analysis.

From a terminal on your workstation, issue repeated requests to the application endpoint:

```bash
for i in {1..30}; do
  curl -s -o /dev/null -w "%{http_code}\n" https://app.devlab405.click/list
  sleep 2
done
```

[RECOMMENDED] Run this command in a loop for 5–10 minutes to create a steady stream of logs in both WAF and app log groups. This will allow you to see normal traffic patterns and have data to analyze when you trigger the incident. It will also help ensure that your WAF logs are flowing into CloudWatch Logs as expected.

1. Open **AWS Console → CloudWatch → Logs Insights**
2. Select the log group:

[CAUTION] You will need to run separate queries for WAF and app logs, so select the appropriate log group for each set of queries: For WAF queries, select `aws-waf-logs-lab-1c-webacl`. For application queries, select `/aws/ec2/lab-rds-app`.

   - WAF queries: `aws-waf-logs-lab-1c-webacl`
   - App queries: `/aws/ec2/lab-rds-app`

3. Set the **time range** to **Last 15 minutes** (or match the incident window from the alarm)
4. Paste a query from below and click **Run query**
5. Review the results table and histogram
6. Capture screenshots for deliverables when required

---

# A) WAF Queries (CloudWatch Logs Insights)

### A1) What’s happening right now? (Top actions: ALLOW/BLOCK)

Select the WAF log group (`aws-waf-logs-lab-1c-webacl`) and run:

```sql
fields @timestamp, action
| stats count() as hits by action
| sort hits desc
```
**CloudWatch Logs Insights**    
region: ap-northeast-1    
log-group-names: aws-waf-logs-lab-1c-webacl    
data-sources:     
facets:     
start-time: -10800s    
end-time: 0s    
query-string:
  ```
  fields @timestamp, action
| stats count() as hits by action
| sort hits desc
  ```
---
| action | hits |
| --- | --- |
| ALLOW | 391 |
| BLOCK | 126 |
---


### A2) Top client IPs (who is hitting us the most?)

Select the WAF log group (`aws-waf-logs-lab-1c-webacl`) and run:

```sql
fields @timestamp, httpRequest.clientIp as clientIp
| stats count() as hits by clientIp
| sort hits desc
| limit 25
```


**CloudWatch Logs Insights**    
region: ap-northeast-1    
log-group-names: aws-waf-logs-lab-1c-webacl    
data-sources:     
facets:     
start-time: -900s    
end-time: 0s    
query-string:
  ```
  fields @timestamp, httpRequest.clientIp as clientIp
| stats count() as hits by clientIp
| sort hits desc
| limit 25
  ```
---
| clientIp | hits |
| --- | --- |
| 178.24.86.77 | 15 |
| 86.54.31.38 | 5 |
| 43.159.148.221 | 2 |
| 18.97.19.254 | 1 |
| 44.242.252.196 | 1 |

### A3) Top requested URIs (what are they trying to reach?)

Select the WAF log group (`aws-waf-logs-lab-1c-webacl`) and run:

```sql
fields @timestamp, httpRequest.uri as uri
| stats count() as hits by uri
| sort hits desc
| limit 25
```

**CloudWatch Logs Insights**    
region: ap-northeast-1    
log-group-names: aws-waf-logs-lab-1c-webacl    
data-sources:     
facets:     
start-time: -10800s    
end-time: 0s    
query-string:
  ```
  fields @timestamp, httpRequest.uri as uri
| stats count() as hits by uri
| sort hits desc
| limit 25
  ```
---
| uri | hits |
| --- | --- |
| &#x2f; | 53 |
| &#x2f;list | 48 |
| &#x2f;add | 10 |
| &#x2f;_next | 6 |
| &#x2f;.env | 4 |
| &#x2f;.git&#x2f;config | 3 |
| &#x2f;index.php | 3 |
| &#x2f;app&#x2f;.env | 2 |
| &#x2f;api&#x2f;files&#x2f;upload | 2 |
| &#x2f;.AwS&#x2f;CrEdEnTiAlS | 2 |
| &#x2f;aWs-cOdEcOmMiT&#x2f; | 2 |
| &#x2f;form&#x2f;v1&#x2f;media | 2 |
| &#x2f;form&#x2f;fileupload | 2 |
| &#x2f;.EnV.SaVe | 2 |
| &#x2f;api&#x2f;assets&#x2f;upload | 2 |
| &#x2f;form&#x2f;assets | 2 |
| &#x2f;.env.dev | 2 |
| &#x2f;api&#x2f;images&#x2f;upload | 2 |
| &#x2f;form&#x2f;files | 2 |
| &#x2f;form&#x2f;file | 2 |
| &#x2f;upload&#x2f;image | 2 |
| &#x2f;form&#x2f;profile&#x2f;avatar | 2 |
| &#x2f;admin&#x2f;media | 2 |
| &#x2f;form&#x2f;multipart | 2 |
| &#x2f;api&#x2f;s3&#x2f;upload | 2 |
---


### A4) Blocked requests only (who/what is being blocked?)

Select the WAF log group (`aws-waf-logs-lab-1c-webacl`) and run:

```sql
fields @timestamp, action, httpRequest.clientIp as clientIp, httpRequest.uri as uri
| filter action = "BLOCK"
| stats count() as blocks by clientIp, uri
| sort blocks desc
| limit 25
```

**CloudWatch Logs Insights**    
region: ap-northeast-1    
log-group-names: aws-waf-logs-lab-1c-webacl    
data-sources:     
facets:     
start-time: -10800s    
end-time: 0s    
query-string:
  ```
  fields @timestamp, action, httpRequest.clientIp as clientIp, httpRequest.uri as uri
| filter action = "BLOCK"
| stats count() as blocks by clientIp, uri
| sort blocks desc
| limit 25
  ```
---
| clientIp | uri | blocks |
| --- | --- | --- |
| 185.177.72.23 | &#x2f;admin&#x2f;files | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;batch&#x2f;upload | 2 |
| 185.177.72.23 | &#x2f;files&#x2f;upload | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;profile&#x2f;photo | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;products&#x2f;upload | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;blob | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;blob&#x2f;upload | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;media&#x2f;upload | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;s3&#x2f;upload | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;content&#x2f;upload | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;storage | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;images&#x2f;upload | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;attachments | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;assets | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;drive&#x2f;upload | 2 |
| 185.177.72.23 | &#x2f;import | 2 |
| 185.177.72.23 | &#x2f;admin&#x2f;media | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;v1&#x2f;upload | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;media | 2 |
| 62.171.164.240 | &#x2f;index.php | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;resources&#x2f;upload | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;gallery&#x2f;upload | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;catalog&#x2f;images | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;files | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;v1&#x2f;files | 2 |
---



### A5) Which WAF rule is doing the blocking?
Select the WAF log group (`aws-waf-logs-lab-1c-webacl`) and run:

```sql
fields @timestamp, action, terminatingRuleId, terminatingRuleType
| filter action = "BLOCK"
| stats count() as blocks by terminatingRuleId, terminatingRuleType
| sort blocks desc
| limit 25
```

**CloudWatch Logs Insights**    
region: ap-northeast-1    
log-group-names: aws-waf-logs-lab-1c-webacl    
data-sources:     
facets:     
start-time: -10800s    
end-time: 0s    
query-string:
  ```
  fields @timestamp, action, terminatingRuleId, terminatingRuleType
| filter action = "BLOCK"
| stats count() as blocks by terminatingRuleId, terminatingRuleType
| sort blocks desc
| limit 25
  ```
---
| terminatingRuleId | terminatingRuleType | blocks |
| --- | --- | --- |
| AWSManagedRulesCommonRuleSet | MANAGED_RULE_GROUP | 126 |
---


### Controlled error generation (simulate scanner traffic)

To get started we will generate "known errors" by making the WAF see "scanner" traffic (e.g. curl https://app.devlab405.click/wp-login) which should trigger WAF blocks and generate errors in the app logs (e.g. connection refused, timeout, etc.). This will allow us to see real error patterns in the logs that we can then use for triage when an incident occurs.

[CAUTION] This will generate real WAF blocks and app errors, so only run this in a test environment where you have permission to do so.

These are for A6 and A7 queries below, which look for common scanner patterns. Run this command in a terminal to generate traffic that will trigger WAF blocks and app errors:

[NOTE] You can adjust the paths and frequency as needed. The example below hits common scanner paths like wp-login, .env, admin, phpmyadmin, .git, etc. 10 times each with a 1-second delay. A print statement is included to show which path is being hit and it will generate WAF blocks for those paths if your WAF rules are configured to block them.

This also provides you with real log data in both WAF and app logs that you can analyze with the queries below to see what scanner traffic looks like in your logs. You can run this command multiple times to generate more data if needed.

```bash
for path in wp-login .env admin phpmyadmin .git login; do
  echo "Hitting path: /$path"
  for i in {1..10}; do
    curl -s -o /dev/null -w "  HTTP %{http_code}\n" \
      "https://app.devlab405.click/$path"
    sleep 1
  done
done
```

### A6) Rate of suspicious patterns (common scans)

Use this regex-based version (recommended):

Select the WAF log group (`aws-waf-logs-lab-1c-webacl`) and run:

```sql
fields @timestamp, httpRequest.clientIp as clientIp, httpRequest.uri as uri
| filter uri =~ /wp-login|xmlrpc|\.env|admin|phpmyadmin|\.git|login/
| stats count() as hits by clientIp, uri
| sort hits desc
| limit 50
```

**CloudWatch Logs Insights**    
region: ap-northeast-1    
log-group-names: aws-waf-logs-lab-1c-webacl    
data-sources:     
facets:     
start-time: -3600s    
end-time: 0s    
query-string:
  ```
  fields @timestamp, httpRequest.clientIp as clientIp, httpRequest.uri as uri
| filter uri =~ /wp-login|xmlrpc|\.env|admin|phpmyadmin|\.git|login/
| stats count() as hits by clientIp, uri
| sort hits desc
| limit 50
  ```
---
| clientIp | uri | hits |
| --- | --- | --- |
| 178.24.86.77 | &#x2f;wp-login | 21 |
| 178.24.86.77 | &#x2f;.env | 17 |
| 178.24.86.77 | &#x2f;admin | 14 |
| 178.24.86.77 | &#x2f;phpmyadmin | 14 |
| 178.24.86.77 | &#x2f;.git | 13 |
| 178.24.86.77 | &#x2f;login | 9 |
| 185.177.72.23 | &#x2f;.env | 4 |
| 185.177.72.23 | &#x2f;admin&#x2f;files | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;mail&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;.env.save | 2 |
| 185.177.72.23 | &#x2f;form&#x2f;admin&#x2f;import | 2 |
| 185.177.72.23 | &#x2f;env&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;admin&#x2f;media | 2 |
| 185.177.72.23 | &#x2f;form&#x2f;admin&#x2f;files | 2 |
| 185.177.72.23 | &#x2f;&#x2f;&#x2f;&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;.env.php | 2 |
| 185.177.72.23 | &#x2f;form&#x2f;admin&#x2f;upload | 2 |
| 185.177.72.23 | &#x2f;.env_example | 2 |
| 185.177.72.23 | &#x2f;app&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;project&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;admin&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;backend&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;.env.staging | 2 |
| 185.177.72.23 | &#x2f;home&#x2f;admin&#x2f;.aws&#x2f;credentials | 2 |
| 185.177.72.23 | &#x2f;.env.bak | 2 |
| 185.177.72.23 | &#x2f;demo&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;.env.www | 2 |
| 185.177.72.23 | &#x2f;.git&#x2f;config | 2 |
| 185.177.72.23 | &#x2f;.env.backup | 2 |
| 185.177.72.23 | &#x2f;admin&#x2f;upload | 2 |
| 185.177.72.23 | &#x2f;dev&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;main&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;.env.example | 2 |
| 185.177.72.23 | &#x2f;docs&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;.env.production | 2 |
| 185.177.72.23 | &#x2f;.env.dev | 2 |
| 185.177.72.23 | &#x2f;nginx&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;portal&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;.env.live | 2 |
---


### A7) Suspicious scanners (same as A6; alternate naming)

Select the WAF log group (`aws-waf-logs-lab-1c-webacl`) and run:

```sql
fields @timestamp, httpRequest.clientIp as clientIp, httpRequest.uri as uri
| filter uri =~ /wp-login|xmlrpc|\.env|admin|phpmyadmin|\.git|login/
| stats count() as hits by clientIp, uri
| sort hits desc
| limit 50
```

**CloudWatch Logs Insights**    
region: ap-northeast-1    
log-group-names: aws-waf-logs-lab-1c-webacl    
data-sources:     
facets:     
start-time: -3600s    
end-time: 0s    
query-string:
  ```
  fields @timestamp, httpRequest.clientIp as clientIp, httpRequest.uri as uri
| filter uri =~ /wp-login|xmlrpc|\.env|admin|phpmyadmin|\.git|login/
| stats count() as hits by clientIp, uri
| sort hits desc
| limit 50
  ```
---
| clientIp | uri | hits |
| --- | --- | --- |
| 178.24.86.77 | &#x2f;wp-login | 24 |
| 178.24.86.77 | &#x2f;admin | 20 |
| 178.24.86.77 | &#x2f;.env | 20 |
| 178.24.86.77 | &#x2f;phpmyadmin | 20 |
| 178.24.86.77 | &#x2f;login | 19 |
| 178.24.86.77 | &#x2f;.git | 19 |
| 185.177.72.23 | &#x2f;.env | 4 |
| 185.177.72.23 | &#x2f;admin&#x2f;files | 2 |
| 185.177.72.23 | &#x2f;api&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;project&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;form&#x2f;admin&#x2f;import | 2 |
| 185.177.72.23 | &#x2f;admin&#x2f;media | 2 |
| 185.177.72.23 | &#x2f;form&#x2f;admin&#x2f;files | 2 |
| 185.177.72.23 | &#x2f;.env.php | 2 |
| 185.177.72.23 | &#x2f;admin&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;mail&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;env&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;.env_example | 2 |
| 185.177.72.23 | &#x2f;form&#x2f;admin&#x2f;upload | 2 |
| 185.177.72.23 | &#x2f;&#x2f;&#x2f;&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;app&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;.env.save | 2 |
| 185.177.72.23 | &#x2f;main&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;.env.bak | 2 |
| 185.177.72.23 | &#x2f;.git&#x2f;config | 2 |
| 185.177.72.23 | &#x2f;dev&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;.env.example | 2 |
| 185.177.72.23 | &#x2f;docs&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;backend&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;home&#x2f;admin&#x2f;.aws&#x2f;credentials | 2 |
| 185.177.72.23 | &#x2f;demo&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;.env.www | 2 |
| 185.177.72.23 | &#x2f;.env.staging | 2 |
| 185.177.72.23 | &#x2f;admin&#x2f;upload | 2 |
| 185.177.72.23 | &#x2f;.env.backup | 2 |
| 185.177.72.23 | &#x2f;.env.production | 2 |
| 185.177.72.23 | &#x2f;.env.dev | 2 |
| 185.177.72.23 | &#x2f;.env.live | 2 |
| 185.177.72.23 | &#x2f;nginx&#x2f;.env | 2 |
| 185.177.72.23 | &#x2f;portal&#x2f;.env | 2 |
---



### A8) Country/geo (if present in your WAF logs)

Some WAF formats include httpRequest.country. If yours does:

Select the WAF log group (`aws-waf-logs-lab-1c-webacl`) and run:

```sql
fields @timestamp, httpRequest.country as country
| stats count() as hits by country
| sort hits desc
| limit 25
```

**CloudWatch Logs Insights**    
region: ap-northeast-1    
log-group-names: aws-waf-logs-lab-1c-webacl    
data-sources:     
facets:     
start-time: -3600s    
end-time: 0s    
query-string:
  ```
  fields @timestamp, httpRequest.country as country
| stats count() as hits by country
| sort hits desc
| limit 25
  ```
---
| country | hits |
| --- | --- |
| FR | 349 |
| DE | 139 |
| TW | 20 |
| US | 6 |
| NL | 5 |
| PT | 2 |
| BR | 2 |
---

### B) App Queries (EC2 app log group)

These queries assume your app logs include meaningful strings like:
ERROR, Exception, Traceback, DBConnectionErrors, timeout, refused, etc.

[NOTE] Under normal operation you may see some errors in the logs (e.g. occasional timeouts, connection issues, etc.) but during an incident you would expect to see a significant spike in these error patterns that align with the incident window.

To support seeing actual error patterns (e.g. connection refused, timeout, access denied) in the logs, make sure to run the "Controlled error generation" command below before your incident occurs. This will create real errors in the logs that you can then analyze with these queries to see what they look like and use that knowledge for triage when an incident happens.

### Controlled Backend Error Failure (Auth)

To generate real backend errors that you can see in the logs, we will temporarily change the database credentials in the application to invalid values. This will cause authentication failures when the app tries to connect to the database, which will generate error patterns in the logs that you can analyze with the queries below.

[CAUTION] This will cause real errors in the application, so only run this in a test environment where you have permission to do so.

Keep CloudWatch Logs Insights open and run the queries below to see the error patterns in real time as you generate them.

1. Save the current database credentials from Parameter Store or Secrets Manager so you can restore them later.


```
aws secretsmanager get-secret-value \
--secret-id lab-1c/rds/mysql \
--region ap-northeast-1 \   
--query 'SecretString' \
--output text
```

2. Update the credentials in Secrets Manager to invalid values (e.g. change the password to "wrongpassword"):

You will need to update the `--secret-string` with the correct format that your application expects. The example below assumes a JSON structure with username, password, host, port, and dbname fields. Adjust as needed based on your application's expected secret format. So don not just copy-paste the example below; make sure to format the `--secret-string` correctly for your app.

```
aws secretsmanager update-secret \
--secret-id lab-1c/rds/mysql \
--region ap-northeast-1 \
--secret-string '{"username":"admin","password":"wrongpassword","host":"lab-1c-rds-instance.abcdefghijk.ap-northeast-1.rds.amazonaws.com","port":3306,"dbname":"mydb"}'
```

[NOTE] This will cause the application to fail to connect to the database, which will generate authentication failure errors in the logs that you can analyze with the queries below. You can then restore the original credentials after you are done.

3. Generate application traffic to trigger the errors:

```bash
for i in {1..30}; do
  curl -s -o /dev/null -w "%{http_code}\n" https://app.devlab405.click/list
  sleep 2
done
```

Wait a few minutes for the errors to appear in the logs, then run the queries below to see the error patterns.

4. Run queries B1, B2 and B3 (Credentials/Auth) below to see the authentication failure patterns in the logs.

### B1) Count errors over time (align with alarm window)

Select the app log group (`/aws/ec2/lab-rds-app`) and run:

```sql
fields @timestamp, @message
| filter @message like "ERROR" or @message like "Exception" or @message like "timeout" or @message like "refused" or @message like "Access denied"
| stats count() as errors by @timestamp
| sort @timestamp asc
| limit 200
```


[
    {
        "@timestamp": "2026-02-07 11:31:18.864",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:31:21.621",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:31:24.631",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:31:27.389",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:31:30.147",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:31:32.904",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:31:35.662",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:31:38.669",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:31:41.427",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:31:44.188",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:31:46.946",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:31:49.955",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:31:52.714",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:31:55.473",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:31:58.483",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:32:01.241",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:32:03.999",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:32:06.759",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:32:09.516",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:32:12.526",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:32:15.285",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:32:18.043",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:32:20.802",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:32:23.563",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:32:26.321",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:32:29.079",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:32:32.088",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:32:34.846",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:32:37.604",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:32:40.362",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:51:58.336",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:52:01.094",
        "errors": "1"
    },
    {
        "@timestamp": "2026-02-07 11:52:03.852",
        "errors": "1"
    }
]

### B2) Look for authentication failures (e.g. DB connection errors)

```
fields @timestamp, @message
| filter @message =~ /(DB|mysql|timeout|refused|Access denied|could not connect)/
| sort @timestamp desc
| limit 50

```

[
    {
        "@timestamp": "2026-02-07 11:52:03.852",
        "@message": "2026-02-07 11:52:03,804 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:52:01.094",
        "@message": "2026-02-07 11:52:00,981 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:51:58.336",
        "@message": "2026-02-07 11:51:58,169 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:32:40.362",
        "@message": "2026-02-07 11:32:40,279 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:32:37.604",
        "@message": "2026-02-07 11:32:37,470 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:32:34.846",
        "@message": "2026-02-07 11:32:34,652 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:32:32.088",
        "@message": "2026-02-07 11:32:31,856 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:32:29.079",
        "@message": "2026-02-07 11:32:29,059 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:32:26.321",
        "@message": "2026-02-07 11:32:26,264 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:32:23.563",
        "@message": "2026-02-07 11:32:23,452 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:32:20.802",
        "@message": "2026-02-07 11:32:20,662 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:32:18.043",
        "@message": "2026-02-07 11:32:17,878 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:32:15.285",
        "@message": "2026-02-07 11:32:15,082 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:32:12.526",
        "@message": "2026-02-07 11:32:12,294 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:32:09.516",
        "@message": "2026-02-07 11:32:09,480 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:32:06.759",
        "@message": "2026-02-07 11:32:06,677 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:32:03.999",
        "@message": "2026-02-07 11:32:03,872 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:32:01.241",
        "@message": "2026-02-07 11:32:01,084 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:31:58.483",
        "@message": "2026-02-07 11:31:58,245 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:31:55.473",
        "@message": "2026-02-07 11:31:55,444 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:31:52.714",
        "@message": "2026-02-07 11:31:52,577 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:31:49.955",
        "@message": "2026-02-07 11:31:49,767 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:31:46.946",
        "@message": "2026-02-07 11:31:46,898 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:31:44.188",
        "@message": "2026-02-07 11:31:44,105 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:31:41.427",
        "@message": "2026-02-07 11:31:41,240 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:31:38.669",
        "@message": "2026-02-07 11:31:38,438 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:31:35.662",
        "@message": "2026-02-07 11:31:35,575 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:31:32.904",
        "@message": "2026-02-07 11:31:32,775 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:31:30.147",
        "@message": "2026-02-07 11:31:29,964 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:31:27.389",
        "@message": "2026-02-07 11:31:27,176 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:31:24.631",
        "@message": "2026-02-07 11:31:24,381 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:31:21.621",
        "@message": "2026-02-07 11:31:21,589 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    },
    {
        "@timestamp": "2026-02-07 11:31:18.864",
        "@message": "2026-02-07 11:31:18,781 ERROR DB_CONNECTION_ERROR (1045, \"Access denied for user 'appuser'@'10.30.11.133' (using password: YES)\")"
    }
]

4. Restore original credentials (post testing cleanup)

Here you have two options to restore the original credentials:
(1) Update the secret in Secrets Manager back to the original values you saved in step 1, or (2) leverage Terraform to manage the secret and run `terraform apply` to restore the known-good state.

[OPTION 1] Restore via AWS CLI:

```
aws secretsmanager update-secret \
--secret-id lab-1c/rds/mysql \
--region ap-northeast-1 \
--secret-string '{"username":"admin","password":"originalpassword","host":"lab-1c-rds-instance.abcdefghijk.ap-northeast-1.rds.amazonaws.com","port":3306,"dbname":"mydb"}'
```
[OPTION 2] Restore via Terraform:

[4.1] Update your Terraform code with the original credentials (make sure to use the correct format that your application expects):

```hcl
resource "aws_secretsmanager_secret_version" "rds_mysql" {
  secret_id     = aws_secretsmanager_secret.rds_mysql.id
  secret_string = jsonencode({
    username = "admin",
    password = "originalpassword",
    host     = "lab-1c-rds-instance.abcdefghijk.ap-northeast1.rds.amazonaws.com",
    port     = 3306,
    dbname   = "mydb"
  })
}
```
[NOTE] This assumes you have a Terraform resource defined for the secret (e.g. `aws_secretsmanager_secret.rds_mysql`) and that you are using Terraform to manage the secret. Adjust the resource name and structure as needed based on your existing Terraform code. If Terraform is managing your secret, it's best practice to use Terraform to make changes to it to ensure the state remains consistent. 

[4.2] run command `terraform plan` to see the proposed changes, then run `terraform apply` to update the secret in Secrets Manager with the original credentials, which will restore the application's ability to connect to the database and resolve the authentication errors in the logs.

If you see that the authenticaton is still occuring you may have to force Terraform to update the secret by tainting the resource first. 

We will **NOT** run `terraform taint` directly, but instead we will use the `-replace` option with `terraform apply` to force replacement of the secret version resource. This is because sometimes when you update a secret in Secrets Manager, it creates a new version of the secret, and Terraform may not automatically detect that change and update the state accordingly. By using `-replace`, we can force Terraform to create a new version of the secret with the updated credentials.

- List the secretsmanager_secret_version resources in your Terraform state to find the correct resource name:

```
terraform state list | grep secretsmanager_secret_version
```

[NOTE] This will show you the list of secretsmanager_secret_version resources in your Terraform state. Identify the one that corresponds to your RDS MySQL secret (e.g. `aws_secretsmanager_secret_version.rds_mysql`), then run the taint command with the correct resource name.

You should see output like:

```
module.secrets.aws_secretsmanager_secret_version.rds_secret_version[0]
```
- Force Terraform to recreate the secret version by tainting the resource:

```
terraform apply \
  -replace=module.secrets.aws_secretsmanager_secret_version.rds_secret_version[0]
```

- This will mark the specified secret version resource for replacement, and when you run `terraform apply`, it will create a new version of the secret with the original credentials, which should resolve the authentication errors in the application logs.   

Verify that the application can connect to the database successfully and that the authentication errors in the logs have stopped.

``` 
    aws secretsmanager get-secret-value \
    --secret-id lab-1c/rds/mysql \
    --region ap-northeast-1 \   
    --query 'SecretString' \
    --output text
``` 

Verify that the application can connect to the database successfully and that the authentication errors in the logs have stopped. 

```
curl -I https://app.devlab405.click/list
```
 You should see a successful HTTP response (e.g. 200 OK) indicating that the application is able to connect to the database and serve requests again.

 $ curl -I https://app.devlab405.click/list
HTTP/2 200 
date: Sat, 07 Feb 2026 12:05:09 GMT
content-type: text/html; charset=utf-8
content-length: 366
server: Werkzeug/3.1.5 Python/3.9.25


### Network or Credential Failures in Logs

In this section we will look for patterns in the logs that indicate network or credential failures when the application tries to connect to the database. This can include authentication failures (e.g. "Access denied for user 'appuser'@'10.30.11.133'"), as well as network-related errors such as timeouts or connection refused. 

We will run step-by-step queries to look for these patterns in the logs, starting with counting the number of errors over time, then looking for specific authentication failure messages, and finally looking for network-related error patterns.

To generate real authentication failures in the logs, make sure to run the "Controlled error generation" steps above before running these queries. This will create real errors in the logs that you can analyze with these queries to see what they look like and use that knowledge for triage when an incident happens.

For the purpose of the lab we generated authentication failures by changing the database credentials to invalid values, which caused the application to fail to connect to the database and generate "Access denied" errors in the logs. In a real incident, you may also see other types of errors such as timeouts or connection refused if there are underlying network issues affecting connectivity between the app and the database.

At this phase we are introducing other possible error patterns to look for in the logs during an incident, such as timeouts or connection refused, which can indicate network connectivity issues between the app and the database.

### Isolate the app from the database to generate real network errors in the logs

### Controlled network outage generation (RDS instance isolation) 

Identify the RDS security group via AWS CLI:

```aws rds describe-db-instances \
--region ap-northeast-1 \
--db-instance-identifier lab-1c-rds-instance \
--query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
--output text
``` 
Save the outout as `RDS_SECURITY_GROUP_ID` for the next steps.

Identify the EC2 instance security group via AWS CLI:

```aws ec2 describe-instances \
--region ap-northeast-1 \
--instance-ids i-0123456789abcdef0 \
--query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
--output text
```
Save the output as `EC2_SECURITY_GROUP_ID` for the next steps.  

[NOTE] If your instance has multiple security groups, you will need to adjust the commands to list all security groups and identify the correct ones.

Block Database Access from EC2 by removing the inbound rule in the RDS security group that allows traffic from the EC2 security group. This will simulate a network connectivity issue between the app and the database, which should generate network-related errors in the logs (e.g. timeouts, connection refused, etc.) when the app tries to connect to the database.

```
aws ec2 revoke-security-group-ingress \
--region ap-northeast-1 \
--group-id RDS_SECURITY_GROUP_ID \
--protocol tcp \
--port 3306 \
--source-group EC2_SECURITY_GROUP_ID
``` 

Generate application traffic to trigger the errors:

```bash
for i in {1..30}; do
  curl -s -o /dev/null -w "%{http_code}\n" https://app.devlab405.click/list
  sleep 2
done
``` 

Wait a few minutes for the errors to appear in the logs, then run the queries below to see the network-related error patterns.  

Review logs for evidence of network-related errors such as timeouts or connection refused that indicate connectivity issues between the app and the database. Look for patterns like "timeout", "refused", "could not connect", etc. in the logs to identify these types of errors.





### B3) Look for network/connection failures (e.g. timeouts, refused connections)

For the purpose of the lab we are generating authentication failures, but in a real incident you may also see network-related errors such as timeouts or connection refused if there are underlying network issues affecting connectivity between the app and the database. 

[CAUTION] The queries below are looking for patterns like "timeout", "refused", "could not connect", etc. If your logs use different wording for these types of errors, you will need to adjust the filter patterns accordingly to match the actual log messages in your application logs. 

The following procedure will isolate the EC2 application from the database to generate real network errors that you can see in the logs. This simulates a scenario where there are network connectivity issues between the app and the database, which can help you understand what those error patterns look like in the logs for triage during an incident.

To summarize the steps:
    1. Network/Route test = temporarily revoke RDS SG ingress from EC2 SG on port 3306

    2. Evidence = 5xx spike and/or “timeout/could not connect” app log messages

    3. Restore = re-authorize the ingress rule (or terraform apply)

Run this query on the app log group (`/aws/ec2/lab-rds-app`) to look for network-related error patterns:

```sql
fields @timestamp, @message
| filter @message like "timeout" or @message like "refused" or @message like "could not connect" or @message like "Health check failed" or @message like "Database connection"
| sort @timestamp desc
| limit 50
``` 

[
    {
        "status": "500",
        "path": "/list",
        "hits": "33"
    }
]



### B4) Extract structured fields (requires JSON logs)

If you emit JSON logs like:
{"level":"ERROR","event":"db_connect_fail","reason":"timeout"}

[OBSERVATION] The query below did not produce any output during the network outage event. Even running the query against entire log history did not produce any results. Need to further investigate why this is the case. 

```
fields @timestamp, level, event, reason
| filter level="ERROR"
| stats count() as n by event, reason
| sort n desc
```

The below query produced results during the network outage event, showing a spike in 500 errors with "could not connect" messages in the logs, which indicates that the application was unable to connect to the database due to the network isolation we created. 

```
fields @timestamp, @message
| parse @message '* * * - - [*] "* * *" * *' as log_ts, level, client_ip, bracket_ts, method, path, proto, status, rest
| filter status = 500 or status = 502 or status = 503 or status = 504
| stats count() as n by status, path
| sort n desc
| limit 25
```

[
    {
        "status": "500",
        "path": "/list",
        "n": "42"
    }
]


[NOTE] this requires structured JSON logging in the application.


### Restore network access by re-adding the inbound rule in the RDS security group that allows traffic from the EC2 security group. This will restore connectivity between the app and the database, which should resolve the network-related errors in the logs.

```
aws ec2 authorize-security-group-ingress \
--region ap-northeast-1 \
--group-id RDS_SECURITY_GROUP_ID \
--protocol tcp \
--port 3306 \
--source-group EC2_SECURITY_GROUP_ID
```

Then confirm that the application can connect to the database successfully and that the network-related errors in the logs have stopped by running the same queries as before to look for those error patterns. You should see that the errors have stopped appearing in the logs, indicating that connectivity between the app and the database has been restored.

```
curl   -I https://app.devlab405.click/list
```
 You should see a successful HTTP response (e.g. 200 OK) indicating that the application is able to connect to the database and serve requests again.   



### C Correlation Workflow — Incident Analysis and Recovery

This section documents how AWS WAF activity, application logs,
CloudWatch alarms, and backend configuration are correlated during an
incident.

The objective is to determine:

-   Whether the incident is driven by **external attack traffic**
-   Or an **internal backend failure** (RDS, Security Groups, or
    Secrets)
-   And to verify controlled recovery using Terraform.

------------------------------------------------------------------------

## Step 1 --- Confirm Signal Timing

1.  Identify the CloudWatch alarm window (typically last 5--15 minutes).
2.  Open CloudWatch Logs Insights for the **application log group**.
3.  Run query **B1** to locate time bins where errors increase.
4.  Record the first timestamp where errors spike.
5.  In the WAF log group, run:
    -   **A1** (ALLOW vs BLOCK)
    -   **A6** (scanner patterns)

Objective: determine whether backend errors and WAF activity occurred at
the same time.

------------------------------------------------------------------------

## Step 2 --- Decide: External Pressure vs Backend Failure

Run:

-   **WAF A1** --- action counts
-   **WAF A6/A7** --- scanner paths

Interpretation:

-   If BLOCK actions spike during the same window → likely external
    scanning or attack traffic.
-   If WAF remains quiet but app errors spike → backend infrastructure
    failure.

------------------------------------------------------------------------

## Step 3 --- Classify Backend Failure

Use **B2**, **B3**, and **B4** to determine failure type.

### Authentication / Secrets Failure

Indicators:

-   Access denied
-   MySQL error 1045
-   Authentication failures after rotation

Conclusion:

Secrets Manager value drift or rotation failure.

------------------------------------------------------------------------

### Network / Security Group Failure

Indicators:

-   timeout
-   could not connect
-   HTTP 5xx responses
-   RDS unreachable

Conclusion:

Security Group ingress rule or routing removed.

------------------------------------------------------------------------

## Step 4 --- Retrieve Known-Good Configuration

Use AWS Systems Manager Parameter Store:

-   /lab/db/endpoint
-   /lab/db/port
-   /lab/db/name

Use AWS Secrets Manager:

-   lab-1c/rds/mysql

------------------------------------------------------------------------

## Step 5 --- Restore and Verify Recovery

After fixing credentials or network access, reconcile infrastructure:

terraform apply -auto-approve

If the secret value must be forced back to Terraform's value:

terraform apply
-replace=module.secrets.aws_secretsmanager_secret_version.rds_secret_version\[0\]
-auto-approve

------------------------------------------------------------------------

### Application Validation

curl https://app.devlab405.click/list

------------------------------------------------------------------------

### Log Verification

Re-run:

-   B1 --- error counts return to baseline
-   A6 --- scanner traffic stabilizes

------------------------------------------------------------------------

### Alarm Status

Confirm:

-   ALB 5xx alarm returns to OK
-   No new SNS alerts fire

------------------------------------------------------------------------

## Outcome

This workflow demonstrates:

-   Detection of internet scanning using AWS WAF
-   Separation of attack traffic from backend failures
-   Secrets Manager credential incidents
-   Security Group--driven outages
-   Controlled Terraform-based recovery
-   Verification via logs and live traffic


## Notes / Limitations

ALB access logs are stored in S3; correlate via ALB CloudWatch metrics and dashboards.

This query pack assumes logs are present in CloudWatch Logs and your selected time window covers the incident.

If logs are sparse, widen the time range to 1 hour and re-run.