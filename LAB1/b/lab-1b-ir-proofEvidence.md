C. Incident Response Proof Evidence of a simulated failure Evidence of alarm triggering Evidence of successful recovery using stored values

Technical Verification Using AWS CLI (Required) You must verify everything via CLI — not screenshots alone. What? You think this is easy?
7.1 Verify Parameter Store Values

aws ssm get-parameters \
  --names /lab/db/endpoint /lab/db/port /lab/db/name \
  --with-decryption
Expected: Parameter names returned Correct DB endpoint and port



7.2 Verify Secrets Manager Value

  aws secretsmanager get-secret-value \
  --secret-id lab/rds/mysql
Expected: JSON output Fields: username password host port

7.3 Verify EC2 Can Read Both Systems From EC2:

aws ssm get-parameter --name /lab/db/host
aws secretsmanager get-secret-value --secret-id dadkid/lab/rds/mysql
Expected: Both commands succeed No AccessDeniedException

7.4 Verify CloudWatch Log Group Exists

aws logs describe-log-groups \
  --log-group-name-prefix /aws/ec2/armageddon-class7-rds-app
Expected: Log group present

7.5 Verify DB Failure Logs Appear Simulate failure (examples): Stop RDS Change DB password in Secrets Manager without updating DB Block SG temporarily

Then check logs:

aws logs filter-log-events \
  --log-group-name /aws/ec2/armageddon-class7-rds-app \
  --filter-pattern "DB_CONNECT_FAIL"
Expected: Explicit DB connection failure messages

7.6 Verify CloudWatch Alarm

aws cloudwatch describe-alarms \
  --alarm-name-prefix armageddon-class7-db-connection-failure
Expected: Alarm present State transitions to ALARM during failure

7.7 Incident Recovery Verification After restoring correct credentials or connectivity:

curl http://54.173.174.189/list
Expected: Application resumes normal operation No redeployment required

Incident-Response Focus (What This Lab Teaches) During recovery, you must: Identify failure source via logs Retrieve correct values from: Parameter Store Secrets Manager Restore service using configuration — not guesswork
This mirrors real on-call workflows.

Common Failure Modes (And Why They Matter) | Failure | Real-World Meaning | | -------------------------- | ------------------------- | | Alarm never fires | Poor observability | | Logs lack detail | Weak incident diagnostics | | EC2 can’t read parameters | IAM misdesign | | Recovery requires redeploy | Fragile architecture |

What Completing Lab 1b Proves If you complete this lab, you can confidently say: “I can operate, monitor, and recover AWS workloads using proper secret management and observability.”

That is mid-level engineer capability, not entry-level.

Reflection Questions: Answer all of these A) Why might Parameter Store still exist alongside Secrets Manager? B) What breaks first during secret rotation? C) Why should alarms be based on symptoms instead of causes?
D) How does this lab reduce mean time to recovery (MTTR)? E) What would you automate next?
