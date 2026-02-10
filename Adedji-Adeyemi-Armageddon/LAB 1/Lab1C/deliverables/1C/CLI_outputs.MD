#1 Verify Parameter Store Values

aws ssm get-parameters \
  --names /lab/db/endpoint /lab/db/port /lab/db/name \
  --with-decryption


  ~ $ aws ssm get-parameters \
>   --names /lab/db/endpoint /lab/db/port /lab/db/name \
>   --with-decryption
{
    "Parameters": [
        {
            "Name": "/lab/db/endpoint",
            "Type": "String",
            "Value": "armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com:3306",
            "Version": 1,
            "LastModifiedDate": "2026-02-09T18:35:58.660000+00:00",
            "ARN": "arn:aws:ssm:ap-northeast-1:420228061920:parameter/lab/db/endpoint",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/name",
            "Type": "String",
            "Value": "labdb",
            "Version": 1,
            "LastModifiedDate": "2026-02-09T18:20:45.650000+00:00",
            "ARN": "arn:aws:ssm:ap-northeast-1:420228061920:parameter/lab/db/name",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/port",
            "Type": "String",
            "Value": "3306",
            "Version": 1,
            "LastModifiedDate": "2026-02-09T18:35:58.673000+00:00",
            "ARN": "arn:aws:ssm:ap-northeast-1:420228061920:parameter/lab/db/port",
            "DataType": "text"
        }
    ],
    "InvalidParameters": []
}
~ $ 

#2. Verify Secrets Manager Value

aws secretsmanager get-secret-value \
  --secret-id lab-1a/rds/mysql

{
    "ARN": "arn:aws:secretsmanager:ap-northeast-1:420228061920:secret:lab-1a/rds/mysql-CrBScM",
    "Name": "lab-1a/rds/mysql",
    "VersionId": "terraform-20260118200225151000000003",
    "SecretString": "{\"db_name\":\"labdb\",\"host\":\"lab-mysql.zzz8o4cwoftn.ap-northeast-1.rds.amazonaws.com\",\"password\":\"Admin2026\",\"port\":3306,\"username\":\"theowaf\"}",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2026-01-18T20:02:24.887000+00:00"
}
~ $ 



#3. Verify EC2 Can Read Both Systems From EC2:

aws ssm get-parameter --name /lab/db/endpoint

{
    "Parameter": {
        "Name": "/lab/db/endpoint",
        "Type": "String",
        "Value": "armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com:3306",
        "Version": 1,
        "LastModifiedDate": "2026-02-09T18:35:58.660000+00:00",
        "ARN": "arn:aws:ssm:ap-northeast-1:420228061920:parameter/lab/db/endpoint",
        "DataType": "text"
    }
}
~ $ 


aws secretsmanager get-secret-value --secret-id armageddon-class-vii/rds/mysql-v2
{
    "ARN": "arn:aws:secretsmanager:ap-northeast-1:420228061920:secret:armageddon-class-vii/rds/mysql-v2-FmS6x0",
    "Name": "armageddon-class-vii/rds/mysql-v2",
    "VersionId": "terraform-20260209224328057200000002",
    "SecretString": "{\"dbname\":\"labdb\",\"host\":\"armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com\",\"password\":\"Bigpimpin6\",\"port\":3306,\"username\":\"admin\"}",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2026-02-09T22:43:28.609000+00:00"
}
~ $ 


#4. Verify CloudWatch Log Group Exists

aws logs describe-log-groups \
  --log-group-name-prefix /aws/ec2/armageddon-class-vii--rds-app

{
    "logGroups": [
        {
            "logGroupName": "/aws/ec2/armageddon-class-vii-rds-app",
            "creationTime": 1770661245778,
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

aws logs filter-log-events \
  --log-group-name /aws/ec2/armageddon-class-vii--rds-app \
  --filter-pattern "ERROR"

 
    "events": [
        {
            "logStreamName": "i-0dd14322351a44cbb",
            "timestamp": 1770661424022,
            "message": "2026-02-09 18:23:43,784 ERROR: \u001b[31m\u001b[1mWARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.\u001b[0m\n * Running on all addresses (0.0.0.0)\n * Running on http://127.0.0.1:80\n * Running on http://10.17.11.211:80",
            "ingestionTime": 1770661429277,
            "eventId": "39487069249982012275907260492273224242667760229922963456"
        },
        {
            "logStreamName": "i-0dd14322351a44cbb",
            "timestamp": 1770661428779,
            "message": "2026-02-09 18:23:43,784 ERROR: \u001b[33mPress CTRL+C to quit\u001b[0m",
            "ingestionTime": 1770661429277,
            "eventId": "39487069356066657185317434776558636065656015913871802369"
        },
        {
            "logStreamName": "i-0dd14322351a44cbb",
            "timestamp": 1770677084054,
            "message": "2026-02-09 22:44:42,982 ERROR: \u001b[31m\u001b[1mWARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.\u001b[0m\n * Running on all addresses (0.0.0.0)\n * Running on http://127.0.0.1:80\n * Running on http://10.17.11.211:80",
            "ingestionTime": 1770677090205,
            "eventId": "39487418480365445111818655815050734041025801761391247360"
        },
        {
            "logStreamName": "i-0dd14322351a44cbb",
            "timestamp": 1770677090268,
            "message": "2026-02-09 22:44:42,983 ERROR: \u001b[33mPress CTRL+C to quit\u001b[0m",
            "ingestionTime": 1770677095280,
            "eventId": "39487418618942275775487948022689035116037047695825895424"
        },
        {
            "logStreamName": "i-0dd14322351a44cbb",
            "timestamp": 1770678185137,
:

#5 Verify CloudWatch Alarm

aws cloudwatch describe-alarms \
  --alarm-name-prefix armageddon-class-vii-db-connection-failure
{
    "MetricAlarms": [
        {
            "AlarmName": "armageddon-class-vii-db-connection-failure",
            "AlarmArn": "arn:aws:cloudwatch:ap-northeast-1:420228061920:alarm:armageddon-class-vii-db-connection-failure",
            "AlarmConfigurationUpdatedTimestamp": "2026-02-09T18:20:57.950000+00:00",
            "ActionsEnabled": true,
            "OKActions": [],
            "AlarmActions": [
                "arn:aws:sns:ap-northeast-1:420228061920:armageddon-class-vii-db-incidents"
            ],
            "InsufficientDataActions": [],
            "StateValue": "INSUFFICIENT_DATA",
            "StateReason": "Unchecked: Initial alarm creation",
            "StateUpdatedTimestamp": "2026-02-09T18:20:57.950000+00:00",
            "MetricName": "DBConnectionErrors",
            "Namespace": "Lab/RDSApp",
            "Statistic": "Sum",
            "Dimensions": [],
            "Period": 300,
            "EvaluationPeriods": 1,
            "Threshold": 3.0,
            "ComparisonOperator": "GreaterThanOrEqualToThreshold",
            "TreatMissingData": "missing",
            "StateTransitionedTimestamp": "2026-02-09T18:20:57.950000+00:00"
        }
    ],
    "CompositeAlarms": []
}
     
