LAB-1C Deliverable: Incident Runbook Execution Notes

Goal:
Prove symptom-based alerting and recovery using the existing LAB-1C environment.

Incident Type (choose one):
- [X] Break DB connectivity by changing SG port (recommended)
- [ ] Other (describe):

Failure Injection
- What was changed: Changed port number from 3306 to 3307 in security group.
- Where it was changed (SG / Terraform / Console / CLI):SG
- Start time (UTC): 17:37 UTC
- Expected symptom: application will be unable to reach the database server.


Detection
- First observed error in /var/log/rdsapp.log (timestamp):
- CloudWatch metric observed (timestamp):17:35 UTC
- Alarm entered ALARM (timestamp): 17:40 UTC
- SNS notification received (timestamp):15:41 UTC

aws cloudwatch describe-alarms \
   --region ap-northeast-1 \
   --alarm-names "lab-db-connection-failure" \
   --query 'MetricAlarms[0].StateValue' \
   --output text
ALARM


Response / Recovery
- Recovery action taken: 
 Attempted to access webpage and received error Database error.
![database error webpage](/LAB1/lab_1c/Images/lab1c-database-error-webpage.png)

 Accessed EC2 and attempted to login to database via mysql client from command line. Results no connection.
 
 Tailed log file and observed database connection error in /var/log/rdsapp.log file.

 ![rds log messages](/LAB1/lab_1c/Images/lab1c-rdsapp-logs-show-db-connection-error.png)

 Ran terraform plan and noticed it wanted to make change to security groups for RDS.

 ![terraform console output](/LAB1/lab_1c/Images/lab1c-terraform-sg-port-difference.png)


- Time recovery action started (UTC):17:43 UTC
- Alarm returned to OK (timestamp):

 aws cloudwatch describe-alarms \
   --region ap-northeast-1 \
   --alarm-names "lab-db-connection-failure" \
   --query 'MetricAlarms[0].StateValue' \
   --output text
OK

- App recovered confirmed by:
  - curl http://localhost/health:
  - curl http://<EC2 Public IP>/list

MTTR
- Time from ALARM -> OK (minutes): 17:45 UTC

- SNS message stating status is OKL 17:46 UTC

- Notes / lessons learned:
Unless the responder has access to the EC2 to view logs or other information they will be hard pressed
to determine root cause and recover from an outage.

Also depending on email to provide notification of an outage is hit or miss as individual may be out 
of signal range to receive messages on their mobile device. Also no audible alerts are setup for say 
text messages or automated voice calls.
