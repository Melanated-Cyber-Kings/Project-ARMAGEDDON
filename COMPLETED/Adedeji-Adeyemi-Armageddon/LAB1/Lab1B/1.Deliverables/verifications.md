
ec2_instance_id = "i-00c007dc7ce8dfc59"
private_subnet_ids = [
  "subnet-043f21ebb83a20d91",
  "subnet-0d692b220fdce3efe",
]
public_subnet_ids = [
  "subnet-0b26f93e4855e5ff8",
  "subnet-0b0be0c9c2d2a8b1e",
]
vpc_id = "vpc-0ea7460b22c099c15"




POWERSHELL

##################################################################################################
1.Verify Parameter Store Values

 aws ssm get-parameters \
  --names /lab/db/endpoint /lab/db/port /lab/db/name \
  --with-decryption
##################################################################################################
  {
    "Parameters": [
        {
            "Name": "/lab/db/endpoint",
            "Type": "String",
            "Value": "armageddon-class-vii-rds01.c27i2ikugwbe.us-east-1.rds.amazonaws.com",
            "Version": 1,
            "LastModifiedDate": "2026-02-27T16:26:36.828000+00:00",
            "ARN": "arn:aws:ssm:us-east-1:420228061920:parameter/lab/db/endpoint",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/name",
            "Type": "String",
            "Value": "labdb",
            "Version": 1,
            "LastModifiedDate": "2026-02-27T16:20:53.368000+00:00",
            "ARN": "arn:aws:ssm:us-east-1:420228061920:parameter/lab/db/name",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/port",
            "Type": "String",
            "Value": "3306",
            "Version": 1,
            "LastModifiedDate": "2026-02-27T16:26:36.846000+00:00",
            "ARN": "arn:aws:ssm:us-east-1:420228061920:parameter/lab/db/port",
            "DataType": "text"
        }
    ],
    "InvalidParameters": []
}

##################################################################################################
2.  Verify Secrets Manager Value

aws secretsmanager get-secret-value --secret-id dakid/lab/rds/mysql
##################################################################################################
{
    "ARN": "arn:aws:secretsmanager:us-east-1:420228061920:secret:dakid/lab/rds/mysql-dSeBwz",
    "Name": "dakid/lab/rds/mysql",
    "VersionId": "terraform-20260227162636548700000005",
    "SecretString": "{\"dbname\":\"labdb\",\"host\":\"armageddon-class-vii-rds01.c27i2ikugwbe.us-east-1.rds.amazonaws.com\",\"password\":\"admin2026\",\"port\":3306,\"username\":\"admin\"}",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2026-02-27T16:26:36.635000+00:00"
}

##################################################################################################
3. Verify EC2 Can Read Both Systems From EC2:


aws ssm get-parameters --names /lab/db/endpoint /lab/db/port /lab/db/name --with-decryption
aws secretsmanager get-secret-value --secret-id dakid/lab/rds/mysql

##################################################################################################

sh-5.2$ aws ssm get-parameters --names /lab/db/endpoint /lab/db/port /lab/db/name --with-decryption
{
    "Parameters": [
        {
            "Name": "/lab/db/endpoint",
            "Type": "String",
            "Value": "armageddon-class-vii-rds01.c27i2ikugwbe.us-east-1.rds.amazonaws.com",
            "Version": 1,
            "LastModifiedDate": "2026-02-27T16:26:36.828000+00:00",
            "ARN": "arn:aws:ssm:us-east-1:420228061920:parameter/lab/db/endpoint",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/name",
            "Type": "String",
            "Value": "labdb",
            "Version": 1,
            "LastModifiedDate": "2026-02-27T16:20:53.368000+00:00",
            "ARN": "arn:aws:ssm:us-east-1:420228061920:parameter/lab/db/name",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/port",
            "Type": "String",
            "Value": "3306",
            "Version": 1,
            "LastModifiedDate": "2026-02-27T16:26:36.846000+00:00",
            "ARN": "arn:aws:ssm:us-east-1:420228061920:parameter/lab/db/port",
            "DataType": "text"
        }
    ],
    "InvalidParameters": []
}
sh-5.2$ aws secretsmanager get-secret-value --secret-id dakid/lab/rds/mysql
{
    "ARN": "arn:aws:secretsmanager:us-east-1:420228061920:secret:dakid/lab/rds/mysql-dSeBwz",
    "Name": "dakid/lab/rds/mysql",
    "VersionId": "terraform-20260227162636548700000005",
    "SecretString": "{\"dbname\":\"labdb\",\"host\":\"armageddon-class-vii-rds01.c27i2ikugwbe.us-east-1.rds.amazonaws.com\",\"password\":\"admin2026\",\"port\":3306,\"username\":\"admin\"}",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2026-02-27T16:26:36.635000+00:00"
}
sh-5.2$ 

##################################################################################################
4. Verify CloudWatch Log Group Exists

aws logs describe-log-groups --log-group-name-prefix /aws/ec2/armageddon-class-vii-rds-app
##################################################################################################

{
    "logGroups": [
        {
            "logGroupName": "/aws/ec2/armageddon-class-vii-rds-app",
            "creationTime": 1772209253133,
            "retentionInDays": 7,
            "metricFilterCount": 0,
            "arn": "arn:aws:logs:us-east-1:420228061920:log-group:/aws/ec2/armageddon-class-vii-rds-app:*",
            "storedBytes": 0,
            "logGroupClass": "STANDARD",
            "logGroupArn": "arn:aws:logs:us-east-1:420228061920:log-group:/aws/ec2/armageddon-class-vii-rds-app",
            "deletionProtectionEnabled": false
        }
    ]
}


##################################################################################################


5. Verify DB Failure Logs Appear Simulate failure (examples): Stop RDS Change DB password in Secrets Manager without updating DB Block SG temporarily

Then check logs:

aws logs filter-log-events --log-group-name /aws/ec2/armageddon-class-vii-rds-app  --filter-pattern "ERROR"


##################################################################################################
 aws logs filter-log-events --log-group-name /aws/ec2/armageddon-class-vii-rds-app  --filter-pattern "ERROR"
{
    "events": [],
    "searchedLogStreams": []
}



##################################################################################################

6. Verify CloudWatch Alarm

aws cloudwatch describe-alarms --alarm-name-prefix test-alarm

 
##################################################################################################
 aws cloudwatch describe-alarms --alarm-name-prefix test-alarm             
{
    "MetricAlarms": [
        {
            "AlarmName": "test-alarm",
            "AlarmArn": "arn:aws:cloudwatch:us-east-1:420228061920:alarm:test-alarm",
            "AlarmDescription": "RDS connection",
            "AlarmConfigurationUpdatedTimestamp": "2026-01-23T15:52:52.310000+00:00",
            "ActionsEnabled": true,
            "OKActions": [],
            "AlarmActions": [
                "arn:aws:sns:us-east-1:420228061920:armageddon-class-vii-db-incidents"
            ],
            "InsufficientDataActions": [],
            "StateValue": "ALARM",
            "StateReason": "Threshold Crossed: no datapoints were received for 2 periods and 2 missing datapoints were treated as [Breaching].",
            "StateReasonData": "{\"version\":\"1.0\",\"queryDate\":\"2026-02-27T19:53:39.810+0000\",\"period\":60,\"recentDatapoints\":[],\"recentUpperThresholds\":[],\"evaluatedDatapoints\":[{\"timestamp\":\"2026-02-27T19:52:00.000+0000\"},{\"timestamp\":\"2026-02-27T19:51:00.000+0000\"}]}",
            "StateUpdatedTimestamp": "2026-02-27T19:53:39.811000+00:00",
            "Dimensions": [],
            "EvaluationPeriods": 2,
            "DatapointsToAlarm": 2,
            "ComparisonOperator": "GreaterThanUpperThreshold",
            "TreatMissingData": "breaching",
            "Metrics": [
                {
                    "Id": "m1",
                    "MetricStat": {
                        "Metric": {
                            "Namespace": "AWS/RDS",
                            "MetricName": "DatabaseConnections",
                            "Dimensions": [
                                {
                                    "Name": "DBInstanceIdentifier",
                                    "Value": "armageddon-class-vii-rds01"
                                }
                            ]
                        },
                        "Period": 60,
                        "Stat": "Average"
                    },
                    "ReturnData": true
                },
                {
                    "Id": "ad1",
                    "Expression": "ANOMALY_DETECTION_BAND(m1, 2)",
                    "Label": "DatabaseConnections (expected)",
                    "ReturnData": true
                }
            ],
            "ThresholdMetricId": "ad1",
            "StateTransitionedTimestamp": "2026-02-27T19:53:39.811000+00:00"
        },
        {
            "AlarmName": "test-alarm-sum",
            "AlarmArn": "arn:aws:cloudwatch:us-east-1:420228061920:alarm:test-alarm-sum",
            "AlarmDescription": "RDS connection Error",
            "AlarmConfigurationUpdatedTimestamp": "2026-01-23T15:52:00.158000+00:00",
            "ActionsEnabled": true,
            "OKActions": [],
            "AlarmActions": [
                "arn:aws:sns:us-east-1:420228061920:armageddon-class-vii-db-incidents"
            ],
            "InsufficientDataActions": [],
            "StateValue": "ALARM",
            "StateReason": "Threshold Crossed: no datapoints were received for 2 periods and 2 missing datapoints were treated as [Breaching].",
            "StateReasonData": "{\"version\":\"1.0\",\"queryDate\":\"2026-02-27T19:53:10.678+0000\",\"statistic\":\"Sum\",\"period\":60,\"recentDatapoints\":[],\"threshold\":3.0,\"evaluatedDatapoints\":[{\"timestamp\":\"2026-02-27T19:52:00.000+0000\"},{\"timestamp\":\"2026-02-27T19:51:00.000+0000\"}]}",   
            "StateUpdatedTimestamp": "2026-02-27T19:53:10.679000+00:00",
            "MetricName": "DatabaseConnections",
            "Namespace": "AWS/RDS",
            "Statistic": "Sum",
            "Dimensions": [
                {
                    "Name": "DBInstanceIdentifier",
                    "Value": "armageddon-class-vii-rds01"
                }
            ],
            "Period": 60,
            "EvaluationPeriods": 2,
            "DatapointsToAlarm": 2,
            "Threshold": 3.0,
            "ComparisonOperator": "GreaterThanOrEqualToThreshold",
            "TreatMissingData": "breaching",
            "StateTransitionedTimestamp": "2026-02-27T19:53:10.679000+00:00"
        }
    ],
    "CompositeAlarms": []
}


##################################################################################################

7. Incident Recovery Verification After restoring correct credentials or connectivity:
curl http://100.54.114.195/list

##################################################################################################
RDS SHUTDOWN

curl : Internal Server Error
The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the
application.
At line:1 char:1
+ curl http://100.54.114.195/list
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (System.Net.HttpWebRequest:HttpWebRequest) [Invoke-WebRequest], WebException
    + FullyQualifiedErrorId : WebCmdletWebResponseException,Microsoft.PowerShell.Commands.InvokeWebRequestCommand


###########################
RDS RESTORED
##########################
curl http://100.54.114.195/list


StatusCode        : 200
StatusDescription : OK
Content           : <h3>Notes</h3><ul></ul>
RawContent        : HTTP/1.1 200 OK
                    Connection: close
                    Content-Length: 23
                    Content-Type: text/html; charset=utf-8
                    Date: Fri, 27 Feb 2026 20:50:30 GMT
                    Server: Werkzeug/3.1.6 Python/3.9.24

                    <h3>Notes</h3><ul></ul>
Forms             : {}
Headers           : {[Connection, close], [Content-Length, 23], [Content-Type, text/html; charset=utf-8], [Date, Fri, 27 Feb 2026 20:50:30 GMT]...}       
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 23


8. Confirm SNS sent email message 

aws sns list-subscriptions-by-topic --region us-east-1 --topic-arn "arn:aws:sns:us-east-1:420228061920:armageddon-class-vii-db-incidents"

{
    "Subscriptions": [
        {
            "SubscriptionArn": "arn:aws:sns:us-east-1:420228061920:armageddon-class-vii-db-incidents:44bf9c73-11d9-4bc5-bace-1327e19cab63",
            "Owner": "420228061920",
            "Protocol": "email",
            "Endpoint": "anthonyade.consulting@gmail.com",
            "TopicArn": "arn:aws:sns:us-east-1:420228061920:armageddon-class-vii-db-incidents"
        }
    ]
}


================
LAB 1B REVIEW
================
A) Parameter Store vs Secrets Manager

Parameter Store handles general config and simple secrets; cost-effective and widely integrated
Secrets Manager manages sensitive secrets requiring automatic rotation and lifecycle management
Both services coexist due to complementary, non-overlapping use cases

B) Primary Failure Point During Rotation

The application fails first — not the rotation mechanism
Root cause: application continues using cached/stale credentials after rotation completes

C) Symptom-Based Alarming

Alert on user-facing impact (error rates, latency, failed logins), not underlying causes
Cause-based alerts generate noise and may miss unexpected failure modes

D) MTTR Reduction

Lab shortens detection and diagnosis time through structured log analysis and verified config retrieval
Repeatable process eliminates guesswork and compresses fault-to-recovery interval

E) Next Automation Target

Automate post-rotation validation: test new secret, confirm service authentication, then promote to production
On failure, auto-rollback to last known-good value to prevent production impact