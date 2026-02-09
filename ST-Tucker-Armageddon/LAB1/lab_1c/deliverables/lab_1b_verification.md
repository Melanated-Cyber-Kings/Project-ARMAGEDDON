📌 Reviewer Note (Instructor Context)

The AWS deployment identifiers shown in this deliverable (such as VPC IDs, subnet IDs, security group IDs, instance IDs, ARNs, and RDS endpoints) were captured from a real lab run and may no longer exist after teardown.

These values are included for instructional and audit-review purposes only, to demonstrate expected output shapes, validation workflows, and security posture verification steps.

Instructors reviewing student submissions should focus on architecture, access paths, IAM scoping, security group relationships, encryption usage, and validation methodology rather than exact identifier matching.

# Verify Parameter Store Values
aws ssm get-parameters \
  --names /lab/db/endpoint /lab/db/port /lab/db/name \
  --with-decryption

  {
    "Parameters": [
        {
            "Name": "/lab/db/endpoint",
            "Type": "String",
            "Value": "lab-mysql.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com",
            "Version": 1,
            "LastModifiedDate": "2026-01-21T19:28:45.178000+01:00",
            "ARN": "arn:aws:ssm:ap-northeast-1:261519058382:parameter/lab/db/endpoint",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/name",
            "Type": "String",
            "Value": "appdb",
            "Version": 1,
            "LastModifiedDate": "2026-01-21T19:28:45.183000+01:00",
            "ARN": "arn:aws:ssm:ap-northeast-1:261519058382:parameter/lab/db/name",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/port",
            "Type": "String",
            "Value": "3306",
            "Version": 1,
            "LastModifiedDate": "2026-01-21T19:28:45.178000+01:00",
            "ARN": "arn:aws:ssm:ap-northeast-1:261519058382:parameter/lab/db/port",
            "DataType": "text"
        }
    ],
    "InvalidParameters": []
}

# Verify Secrets Manager Value

aws secretsmanager get-secret-value \
  --secret-id lab-1c/rds/mysql

  {
    "ARN": "arn:aws:secretsmanager:ap-northeast-1:261519058382:secret:lab-1c/rds/mysql-QBRvym",
    "Name": "lab-1c/rds/mysql",
    "VersionId": "de2aa0d7-4e84-4495-b144-3e3ca49d2dc7",
    "SecretString": "{\n    \"engine\": \"mysql\",\n    \"username\": \"admin\",\n    \"password\": \"StrongPassword123!\",\n    \"port\": 3306,\n    \"host\": \"lab-mysql.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com\",\n    \"dbname\": \"appdb\"\n  }",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2026-01-20T21:15:17.632000+01:00"
}

# Verify EC2 Can Read Both Systems From EC2:
aws ssm get-parameter --name /lab/db/endpoint

{
    "Parameter": {
        "Name": "/lab/db/endpoint",
        "Type": "String",
        "Value": "lab-mysql.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com",
        "Version": 1,
        "LastModifiedDate": "2026-01-21T19:28:45.178000+01:00",
        "ARN": "arn:aws:ssm:ap-northeast-1:261519058382:parameter/lab/db/endpoint",
        "DataType": "text"
    }
}

aws secretsmanager get-secret-value --secret-id lab-1c/rds/mysql

{
    "ARN": "arn:aws:secretsmanager:ap-northeast-1:261519058382:secret:lab-1c/rds/mysql-QBRvym",
    "Name": "lab-1c/rds/mysql",
    "VersionId": "de2aa0d7-4e84-4495-b144-3e3ca49d2dc7",
    "SecretString": "{\n    \"engine\": \"mysql\",\n    \"username\": \"admin\",\n    \"password\": \"StrongPassword123!\",\n    \"port\": 3306,\n    \"host\": \"lab-mysql.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com\",\n    \"dbname\": \"appdb\"\n  }",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2026-01-20T21:15:17.632000+01:00"
}

# Verify EC2 Can Read Both Systems From EC2:
aws ssm get-parameter --name /lab/db/endpoint

{
    "Parameter": {
        "Name": "/lab/db/endpoint",
        "Type": "String",
        "Value": "lab-mysql.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com",
        "Version": 1,
        "LastModifiedDate": "2026-01-21T19:28:45.178000+01:00",
        "ARN": "arn:aws:ssm:ap-northeast-1:261519058382:parameter/lab/db/endpoint",
        "DataType": "text"
    }
}
$ aws ssm get-parameter --name /lab/db/endpoint

{
    "Parameter": {
        "Name": "/lab/db/endpoint",
        "Type": "String",
        "Value": "lab-mysql.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com",
        "Version": 1,
        "LastModifiedDate": "2026-01-21T19:28:45.178000+01:00",
        "ARN": "arn:aws:ssm:ap-northeast-1:261519058382:parameter/lab/db/endpoint",
        "DataType": "text"
    }
}


# Verify CloudWatch Log Group Exists

aws logs describe-log-groups \
  --log-group-name-prefix /aws/ec2/lab-rds-app

  {
    "logGroups": [
        {
            "logGroupName": "/aws/ec2/lab-rds-app",
            "creationTime": 1769020122004,
            "retentionInDays": 7,
            "metricFilterCount": 1,
            "arn": "arn:aws:logs:ap-northeast-1:261519058382:log-group:/aws/ec2/lab-rds-app:*",
            "storedBytes": 0,
            "logGroupClass": "STANDARD",
            "logGroupArn": "arn:aws:logs:ap-northeast-1:261519058382:log-group:/aws/ec2/lab-rds-app",
            "deletionProtectionEnabled": false
        }
    ]
}

# Verify DB Failure Logs Appear Simulate failure (examples): Stop RDS Change DB password in Secrets Manager without updating DB Block SG temporarily

aws logs filter-log-events \
  --log-group-name /aws/ec2/lab-rds-app \
  --filter-pattern "ERROR"

  {
    "events": [],
    "searchedLogStreams": []
}

# Verify CloudWatch Alarm

aws cloudwatch describe-alarms \
  --alarm-name-prefix lab-db-connection-failure

{
    "MetricAlarms": [
        {
            "AlarmName": "lab-db-connection-failure",
            "AlarmArn": "arn:aws:cloudwatch:ap-northeast-1:261519058382:alarm:lab-db-connection-failure",
            "AlarmConfigurationUpdatedTimestamp": "2026-01-21T21:19:42.391000+01:00",
            "ActionsEnabled": true,
            "OKActions": [
                "arn:aws:sns:ap-northeast-1:261519058382:lab-db-incidents"
            ],
            "AlarmActions": [
                "arn:aws:sns:ap-northeast-1:261519058382:lab-db-incidents"
            ],
            "InsufficientDataActions": [],
            "StateValue": "ALARM",
            "StateReason": "Threshold Crossed: 1 datapoint [3.0 (21/01/26 20:17:00)] was greater than or equal to the threshold (3.0).",
            "StateReasonData": "{\"version\":\"1.0\",\"queryDate\":\"2026-01-21T20:22:54.408+0000\",\"startDate\":\"2026-01-21T20:17:00.000+0000\",\"statistic\":\"Sum\",\"period\":300,\"recentDatapoints\":[3.0],\"threshold\":3.0,\"evaluatedDatapoints\":[{\"timestamp\":\"2026-01-21T20:17:00.000+0000\",\"sampleCount\":3.0,\"value\":3.0}]}",
            "StateUpdatedTimestamp": "2026-01-21T21:22:54.411000+01:00",
            "MetricName": "DBConnectionErrors",
            "Namespace": "Lab/RDSApp",
            "Statistic": "Sum",
            "Dimensions": [],
            "Period": 300,
            "EvaluationPeriods": 1,
            "Threshold": 3.0,
            "ComparisonOperator": "GreaterThanOrEqualToThreshold",
            "TreatMissingData": "notBreaching",
            "StateTransitionedTimestamp": "2026-01-21T21:22:54.411000+01:00"
        }
    ],
    "CompositeAlarms": []
}

# Incident Recovery Verification After restoring correct credentials or connectivity

curl http://54.95.168.109/list

<h3>Notes</h3><ul><li>1: first_note</li></ul>


## Set value for START Time
START_TIME=$(( $(date -u +"%s") - 900 ))000
export START_TIME



aws logs filter-log-events \
  --log-group-name "/aws/ec2/lab-rds-app" \
  --filter-pattern "connection refused|timeout|Access denied"

aws logs filter-log-events \
  --log-group-name "/aws/ec2/lab-rds-app" \
  --start-time $START_TIME \
  --region ap-northeast-1

# Confirm SNS sent email message 

aws sns list-subscriptions-by-topic \
>   --region ap-northeast-1 \
>   --topic-arn "arn:aws:sns:ap-northeast-1:261519058382:lab-db-incidents"

{
    "Subscriptions": [
        {
            "SubscriptionArn": "arn:aws:sns:ap-northeast-1:261519058382:lab-db-incidents:b83b396d-f0c5-4927-bff4-c8587c5288e6",
            "Owner": "261519058382",
            "Protocol": "email",
            "Endpoint": "selacious@outlook.com",
            "TopicArn": "arn:aws:sns:ap-northeast-1:261519058382:lab-db-incidents"
        }
    ]
}

