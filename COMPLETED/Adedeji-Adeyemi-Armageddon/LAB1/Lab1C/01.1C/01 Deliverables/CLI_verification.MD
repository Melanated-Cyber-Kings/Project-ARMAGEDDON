# Verify Parameter Store Values

##########################################################

aws ssm get-parameters 
  --names /lab/db/endpoint /lab/db/port /lab/db/name 
  --with-decryption

##########################################################

{
    "Parameters": [
        {
            "Name": "/lab/db/endpoint",
            "Type": "String",
            "Value": "armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com",
            "Version": 1,
            "LastModifiedDate": "2026-03-03T12:56:07.834000+00:00",
            "ARN": "arn:aws:ssm:ap-northeast-1:420228061920:parameter/lab/db/endpoint",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/name",
            "Type": "String",
            "Value": "labdb",
            "Version": 1,
            "LastModifiedDate": "2026-03-03T12:41:24.952000+00:00",
            "ARN": "arn:aws:ssm:ap-northeast-1:420228061920:parameter/lab/db/name",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/port",
            "Type": "String",
            "Value": "3306",
            "Version": 1,
            "LastModifiedDate": "2026-03-03T12:56:07.854000+00:00",
            "ARN": "arn:aws:ssm:ap-northeast-1:420228061920:parameter/lab/db/port",
            "DataType": "text"
        }
    ],
    "InvalidParameters": []
}

#################################################################

# Verify Secrets Manager Value

aws secretsmanager get-secret-value 
  --secret-id armageddon-class-vii/rds/mysql-v0

#################################################################

{
    "ARN": "arn:aws:secretsmanager:ap-northeast-1:420228061920:secret:armageddon-class-vii/rds/mysql-v0-P515DA",
    "Name": "armageddon-class-vii/rds/mysql-v0",
    "VersionId": "terraform-20260303133149565100000002",
    "SecretString": "{\"dbname\":\"labdb\",\"host\":\"armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com\",\"password\":\"Bigpimpin6\",\"port\":3306,\"username\":\"admin\"}",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2026-03-03T13:31:48.113000+00:00"
}

#################################################################


# Verify EC2 Can Read Both Systems From EC2:

aws ssm get-parameter --name /lab/db/endpoint

#################################################################

{
    "Parameter": {
        "Name": "/lab/db/endpoint",
        "Type": "String",
        "Value": "armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com",
        "Version": 1,
        "LastModifiedDate": "2026-03-03T12:56:07.834000+00:00",
        "ARN": "arn:aws:ssm:ap-northeast-1:420228061920:parameter/lab/db/endpoint",
        "DataType": "text"
    }
}

#######################################################################

aws secretsmanager get-secret-value --secret-id armageddon-class-vii/rds/mysql-v0

{
    "ARN": "arn:aws:secretsmanager:ap-northeast-1:420228061920:secret:armageddon-class-vii/rds/mysql-v0-P515DA",       
    "Name": "armageddon-class-vii/rds/mysql-v0",
    "VersionId": "terraform-20260303133149565100000002",
    "SecretString": "{\"dbname\":\"labdb\",\"host\":\"armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com\",\"password\":\"Bigpimpin6\",\"port\":3306,\"username\":\"admin\"}",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2026-03-03T13:31:48.113000+00:00"
}

#########################################################################################

# Verify CloudWatch Log Group Exists

aws logs describe-log-groups `
  --log-group-name-prefix /aws/ec2/armageddon-class-vii-rds-app

##########################################################################################  

{
    "logGroups": [
        {
            "logGroupName": "/aws/ec2/armageddon-class-vii-rds-app",
            "creationTime": 1772541685128,
            "retentionInDays": 7,
            "metricFilterCount": 0,
            "arn": "arn:aws:logs:ap-northeast-1:420228061920:log-group:/aws/ec2/armageddon-class-vii-rds-app:*",       
            "storedBytes": 0,
            "logGroupClass": "STANDARD",
            "logGroupArn": "arn:aws:logs:ap-northeast-1:420228061920:log-group:/aws/ec2/armageddon-class-vii-rds-app", 
            "deletionProtectionEnabled": false
        }
    ]
}

aws logs filter-log-events 
  --log-group-name /aws/ec2/armageddon-class-vii-rds-app 
  --filter-pattern "ERROR"

 {
    "events": [
        {
            "logStreamName": "i-07a34456f946c3141",
            "timestamp": 1772571077244,
            "message": "2026-03-03 20:51:17,176 ERROR: \u001b[31m\u001b[1mWARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.\u001b[0m\n * Running on all addresses (0.0.0.0)\n * Running on http://127.0.0.1:80\n * Running on http://10.17.1.251:80",
            "ingestionTime": 1772571082413,
            "eventId": "39529655939903387310057470567683496214264337956676632576"
        },
        {
            "logStreamName": "i-07a34456f946c3141",
            "timestamp": 1772571082001,
            "message": "2026-03-03 20:51:17,176 ERROR: \u001b[33mPress CTRL+C to quit\u001b[0m",
            "ingestionTime": 1772571082413,
            "eventId": "39529656045988032219467644851968908037252593640625471489"
        }
    ],
    "searchedLogStreams": []
}

####################################################################################


# Verify CloudWatch Alarm

aws cloudwatch describe-alarms `
  --alarm-name-prefix armageddon-class-vii-db-connection-failure

{
    "MetricAlarms": [
        {
            "AlarmName": "armageddon-class-vii-db-connection-failure",
            "AlarmArn": "arn:aws:cloudwatch:ap-northeast-1:420228061920:alarm:armageddon-class-vii-db-connection-failure",
            "AlarmConfigurationUpdatedTimestamp": "2026-03-03T19:35:07.115000+00:00",
            "ActionsEnabled": true,
            "OKActions": [],
            "AlarmActions": [
                "arn:aws:sns:ap-northeast-1:420228061920:armageddon-class-vii-db-incidents"
            ],
            "InsufficientDataActions": [],
            "StateValue": "OK",
            "StateReason": "Threshold Crossed: 1 out of the last 1 datapoints [2.0 (03/03/26 20:02:00)] was not greater than or equal to the threshold (3.0) (minimum 1 datapoint for ALARM -> OK transition).",
            "StateReasonData": "{\"version\":\"1.0\",\"queryDate\":\"2026-03-03T20:07:01.355+0000\",\"startDate\":\"2026-03-03T20:02:00.000+0000\",\"statistic\":\"Sum\",\"period\":300,\"recentDatapoints\":[2.0],\"threshold\":3.0,\"evaluatedDatapoints\":[{\"timestamp\":\"2026-03-03T20:02:00.000+0000\",\"sampleCount\":2.0,\"value\":2.0}]}",
            "StateUpdatedTimestamp": "2026-03-03T20:07:01.356000+00:00",
            "MetricName": "DBConnectionErrors",
            "Namespace": "Lab/RDSApp",
            "Statistic": "Sum",
            "Dimensions": [],
            "Period": 300,
            "EvaluationPeriods": 1,
            "DatapointsToAlarm": 1,
            "Threshold": 3.0,
            "ComparisonOperator": "GreaterThanOrEqualToThreshold",
            "TreatMissingData": "missing",
            "StateTransitionedTimestamp": "2026-03-03T20:07:01.356000+00:00"
        }
    ],
    "CompositeAlarms": []
}
curl http://57.180.249.203/list
<h3>Notes</h3><ul></ul>%                                                 

