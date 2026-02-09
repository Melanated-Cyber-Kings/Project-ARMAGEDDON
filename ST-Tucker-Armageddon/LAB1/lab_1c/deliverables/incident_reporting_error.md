🔴 === INCIDENT RESPONSE - DEBUG MODE ===

📊 1. ALARM DETAILED STATUS
--------------------------
------------------------------------------------------------------------------------------------------------------------
|                                                    DescribeAlarms                                                    |
+----------------------------------------------------------------------------------------------------------------------+
|  lab-db-connection-failure                                                                                           |
|  OK                                                                                                                  |
|  2026-01-21T20:37:54.410000+00:00                                                                                    |
|  Threshold Crossed: no datapoints were received for 1 period and 1 missing datapoint was treated as [NonBreaching].  |
+----------------------------------------------------------------------------------------------------------------------+

Alarm Configuration:
-----------------------------------
|         DescribeAlarms          |
+---------------------------------+
|  DBConnectionErrors             |
|  Lab/RDSApp                     |
|  300                            |
|  1                              |
|  3.0                            |
|  GreaterThanOrEqualToThreshold  |
+---------------------------------+

📈 2. METRICS AVAILABILITY
-------------------------
Checking for DBConnectionErrors metrics:
No metrics found in namespace Lab/RDSApp

Manually pushing test metric...
Waiting 60 seconds for metric to register...
Checking alarm state again:
OK

📱 3. APPLICATION STATUS
----------------------
Testing http://54.95.168.109/list

❌ Application 500 Error - App is broken

🔧 IMMEDIATE FIX NEEDED:
1. SSH to EC2 and check logs:
   ssh -i your-key.pem ec2-user@54.95.168.109
2. Check: sudo tail -f /var/log/web-app/app.log
3. Common issues: Missing Python packages, DB config errors

🎯 4. LAB WORKAROUND
------------------
If metrics still not flowing, you can:

OPTION A: Simulate alarm by setting threshold to 1 and pushing metric:
  aws cloudwatch put-metric-data \
    --namespace 'Lab/RDSApp' \
    --metric-name 'DBConnectionErrors' \
    --value 1 \
    --dimensions LogGroupName=/aws/ec2/lab-rds-app

OPTION B: Temporarily lower alarm threshold:
  aws cloudwatch set-alarm-state \
    --alarm-name lab-db-connection-failure \
    --state-value ALARM \
    --state-reason 'Manual override for lab testing'

OPTION C: Check CloudWatch Agent is running on EC2:
  ssh -i your-key.pem ec2-user@54.95.168.109
  sudo systemctl status amazon-cloudwatch-agent

🤖 5. CLOUDWATCH AGENT CHECK
--------------------------
Quick test - check if logs are being collected:
-----------------------------------------------------------
|                   DescribeLogStreams                    |
+---------------------+-----------------+-----------------+
|  i-0f94bb633935ab2dd|  1769026525182  |  1769026877182  |
+---------------------+-----------------+-----------------+

📝 2. CHECKING ERROR LOGS
------------------------

🔧 3. VERIFYING CONFIGURATION
----------------------------
SSM Parameters:
---------------------------------------------------------------------------------
|                                 GetParameters                                 |
+-------------------+-----------------------------------------------------------+
|  /lab/db/endpoint |  lab-mysql.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com  |
|  /lab/db/name     |  appdb                                                    |
|  /lab/db/port     |  3306                                                     |
+-------------------+-----------------------------------------------------------+

Secrets Manager:
{
  "engine": "mysql",
  "username": "admin",
  "password": "StrongPassword123!",
  "port": 3306,
  "host": "lab-mysql.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com",
  "dbname": "appdb"
}

🏗️  4. CHECKING INFRASTRUCTURE STATUS
-----------------------------------
RDS Status:
-------------------------------------------------------------
|                    DescribeDBInstances                    |
+-----------------------------------------------------------+
|  available                                                |
|  lab-mysql.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com  |
+-----------------------------------------------------------+

EC2 Status:
-------------------
|DescribeInstances|
+-----------------+
|  running        |
|  54.95.168.109  |
+-----------------+

🧪 5. TESTING RECOVERY
---------------------
Testing application at http://54.95.168.109/list

Response:
<!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
✅ === DEBUG COMPLETE ===

🎯 SUMMARY:
1. Alarm: INSUFFICIENT_DATA = No metrics from app
2. App: 500 Error = App is broken

🔧 ACTION PLAN:
1. Fix application 500 error first
2. Ensure app emits CloudWatch metrics on DB failure
3. Wait 5+ minutes for metrics to aggregate
4. Alarm should transition to ALARM