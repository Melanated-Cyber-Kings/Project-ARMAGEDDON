LAB-1C Deliverable: CLI Verification (Same as LAB-1C)

Date (YYYY-MM-DD):
AWS Region:

Paste command outputs below.

1) CloudWatch Log Streams
## aws logs describe-log-streams --region ap-northeast-1 --log-group-name "/aws/ec2/lab-rds-app" --order-by LastEventTime --descending --max-items 5 --output table

sh-5.2$ aws logs describe-log-streams --region ap-northeast-1 --log-group-name "/aws/ec2/lab-rds-app" --order-by LastEventTime --descending --max-items 5 --output table
-------------------------------------------------------------------------------------------------------------------------------------
|                                                        DescribeLogStreams                                                         |
+-----------------------------------------------------------------------------------------------------------------------------------+
||                                                           logStreams                                                            ||
|+---------------------+-----------------------------------------------------------------------------------------------------------+|
||  arn                |  arn:aws:logs:ap-northeast-1:261519058382:log-group:/aws/ec2/lab-rds-app:log-stream:i-00174a6f70327a68a   ||
||  creationTime       |  1769964556543                                                                                            ||
||  firstEventTimestamp|  1769964551464                                                                                            ||
||  lastEventTimestamp |  1769964556774                                                                                            ||
||  lastIngestionTime  |  1769964561777                                                                                            ||
||  logStreamName      |  i-00174a6f70327a68a                                                                                      ||
||  storedBytes        |  0                                                                                                        ||
||  uploadSequenceToken|  49039859660394890528635743195767987005779594726835384271                                                 ||
|+---------------------+-----------------------------------------------------------------------------------------------------------+|

2) Metric Filters
## aws logs describe-metric-filters --region ap-northeast-1 --log-group-name "/aws/ec2/lab-rds-app" --output table

sh-5.2$ aws logs describe-metric-filters --region ap-northeast-1 --log-group-name "/aws/ec2/lab-rds-app" --output table
--------------------------------------------------------------------------------------------------------------------
|                                               DescribeMetricFilters                                              |
+------------------------------------------------------------------------------------------------------------------+
||                                                  metricFilters                                                 ||
|+------------------------+----------------+---------------------+-----------------------+------------------------+|
|| applyOnTransformedLogs | creationTime   |     filterName      |     filterPattern     |     logGroupName       ||
|+------------------------+----------------+---------------------+-----------------------+------------------------+|
||  False                 |  1769964465698 |  DBConnectionErrors |  DB_CONNECTION_ERROR  |  /aws/ec2/lab-rds-app  ||
|+------------------------+----------------+---------------------+-----------------------+------------------------+|
|||                                             metricTransformations                                            |||
||+------------------------------------+--------------------------------+-------------------------+--------------+||
|||             metricName             |        metricNamespace         |       metricValue       |    unit      |||
||+------------------------------------+--------------------------------+-------------------------+--------------+||
|||  DBConnectionErrors                |  Lab/RDSApp                    |  1                      |  None        |||
||+------------------------------------+--------------------------------+-------------------------+--------------+||

3) Alarm State
## aws cloudwatch describe-alarms --region ap-northeast-1 --alarm-names "lab-db-connection-failure" --query 'MetricAlarms[0].StateValue' --output text

sh-5.2$ aws cloudwatch describe-alarms --region ap-northeast-1 --alarm-names "lab-db-connection-failure" --query 'MetricAlarms[0].StateValue' --output text
OK

4) SNS Topic + Subscription
## aws sns list-topics --region ap-northeast-1

sh-5.2$ aws sns list-topics --region ap-northeast-1
{
    "Topics": [
        {
            "TopicArn": "arn:aws:sns:ap-northeast-1:261519058382:lab-db-incidents"
        }
    ]
}


## aws sns list-subscriptions --region ap-northeast-1

aws sns list-subscriptions --region ap-northeast-1

{
    "Subscriptions": [
        {
            "SubscriptionArn": "arn:aws:sns:ap-northeast-1:261519058382:lab-db-incidents:9075f8a0-35b9-4d20-9fef-0b719134f0c1",
            "Owner": "261519058382",
            "Protocol": "email",
            "Endpoint": "selacious@outlook.com",
            "TopicArn": "arn:aws:sns:ap-northeast-1:261519058382:lab-db-incidents"
        },
        {
            "SubscriptionArn": "PendingConfirmation",
            "Owner": "261519058382",
            "Protocol": "email",
            "Endpoint": "selacious@outlook.com",
            "TopicArn": "arn:aws:sns:ap-northeast-1:261519058382:lab-db-incidents"
        }
    ]
}

5) Test application endpoints from within EC2 instance.
# curl http://localhost/init

sh-5.2$ curl http://localhost/init

Initialized labdb + notes table

## curl "http://localhost/add?note=test"

sh-5.2$ curl http://localhost/add?note=test
Inserted note: test


## curl http://localhost/list

sh-5.2$ curl http://localhost/list
1: test

6) Check CloudWatch logs
## aws logs describe-log-streams --log-group-name /aws/ec2/lab-rds-app

sh-5.2$ aws logs describe-log-streams --log-group-name /aws/ec2/lab-rds-app
{
    "logStreams": [
        {
            "logStreamName": "i-00174a6f70327a68a",
            "creationTime": 1769964556543,
            "firstEventTimestamp": 1769964551464,
            "lastEventTimestamp": 1769964556774,
            "lastIngestionTime": 1769964561777,
            "uploadSequenceToken": "49039859660394890528635732070695663723425858909374764269",
            "arn": "arn:aws:logs:ap-northeast-1:261519058382:log-group:/aws/ec2/lab-rds-app:log-stream:i-00174a6f70327a68a",
            "storedBytes": 0
        }
    ]
}

7) Verify secrets
## aws secretsmanager get-secret-value --secret-id lab/rds/mysql

sh-5.2$ aws secretsmanager get-secret-value --secret-id lab/rds/mysql
{
    "ARN": "arn:aws:secretsmanager:ap-northeast-1:261519058382:secret:lab/rds/mysql-vUqUxW",
    "Name": "lab/rds/mysql",
    "VersionId": "terraform-20260201164745478700000002",
    "SecretString": "{\"dbname\":\"labdb\",\"host\":\"lab-mysql.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com\",\"password\":\"StrongPassword123!\",\"port\":\"3306\",\"username\":\"admin\"}",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2026-02-01T16:47:45.645000+00:00"
}

## aws ssm get-parameter --name /lab/db/endpoint

sh-5.2$ aws ssm get-parameter --name /lab/db/endpoint
{
    "Parameter": {
        "Name": "/lab/db/endpoint",
        "Type": "String",
        "Value": "lab-mysql.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com",
        "Version": 1,
        "LastModifiedDate": "2026-02-01T16:47:45.284000+00:00",
        "ARN": "arn:aws:ssm:ap-northeast-1:261519058382:parameter/lab/db/endpoint",
        "DataType": "text"
    }
}

## Verified can connect to database from EC2 command line (this of course only verifies that EC2 can reach SQL server port 3306)

sh-5.2$ sudo dnf install mariadb105
Last metadata expiration check: 0:44:45 ago on Sun Feb  1 16:48:51 2026.
Dependencies resolved.
========================================================================================================================================================
 Package                                      Architecture             Version                                      Repository                     Size
========================================================================================================================================================
Installing:
 mariadb105                                   x86_64                   3:10.5.29-1.amzn2023.0.1                     amazonlinux                   1.5 M
Installing dependencies:
 mariadb-connector-c                          x86_64                   3.3.10-1.amzn2023.0.1                        amazonlinux                   211 k
 mariadb-connector-c-config                   noarch                   3.3.10-1.amzn2023.0.1                        amazonlinux                   9.9 k
 mariadb105-common                            x86_64                   3:10.5.29-1.amzn2023.0.1                     amazonlinux                    28 k
 perl-Sys-Hostname                            x86_64                   1.23-477.amzn2023.0.7                        amazonlinux                    16 k

Transaction Summary
========================================================================================================================================================
Install  5 Packages

Total download size: 1.8 M
Installed size: 19 M
Is this ok [y/N]: y
Downloading Packages:
(1/5): mariadb-connector-c-config-3.3.10-1.amzn2023.0.1.noarch.rpm                                                      226 kB/s | 9.9 kB     00:00    
(2/5): mariadb-connector-c-3.3.10-1.amzn2023.0.1.x86_64.rpm                                                             4.2 MB/s | 211 kB     00:00    
(3/5): mariadb105-10.5.29-1.amzn2023.0.1.x86_64.rpm                                                                      22 MB/s | 1.5 MB     00:00    
(4/5): mariadb105-common-10.5.29-1.amzn2023.0.1.x86_64.rpm                                                              899 kB/s |  28 kB     00:00    
(5/5): perl-Sys-Hostname-1.23-477.amzn2023.0.7.x86_64.rpm                                                               549 kB/s |  16 kB     00:00    
--------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                    14 MB/s | 1.8 MB     00:00     
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                                1/1 
  Installing       : mariadb-connector-c-config-3.3.10-1.amzn2023.0.1.noarch                                                                        1/5 
  Installing       : mariadb-connector-c-3.3.10-1.amzn2023.0.1.x86_64                                                                               2/5 
  Installing       : mariadb105-common-3:10.5.29-1.amzn2023.0.1.x86_64                                                                              3/5 
  Installing       : perl-Sys-Hostname-1.23-477.amzn2023.0.7.x86_64                                                                                 4/5 
  Installing       : mariadb105-3:10.5.29-1.amzn2023.0.1.x86_64                                                                                     5/5 
  Running scriptlet: mariadb105-3:10.5.29-1.amzn2023.0.1.x86_64                                                                                     5/5 
  Verifying        : mariadb-connector-c-3.3.10-1.amzn2023.0.1.x86_64                                                                               1/5 
  Verifying        : mariadb-connector-c-config-3.3.10-1.amzn2023.0.1.noarch                                                                        2/5 
  Verifying        : mariadb105-3:10.5.29-1.amzn2023.0.1.x86_64                                                                                     3/5 
  Verifying        : mariadb105-common-3:10.5.29-1.amzn2023.0.1.x86_64                                                                              4/5 
  Verifying        : perl-Sys-Hostname-1.23-477.amzn2023.0.7.x86_64                                                                                 5/5 
========================================================================================================================================================
WARNING:
  A newer release of "Amazon Linux" is available.

  Available Versions:

  Version 2023.10.20260120:
    Run the following command to upgrade to 2023.10.20260120:

      dnf upgrade --releasever=2023.10.20260120

    Release notes:
     https://docs.aws.amazon.com/linux/al2023/release-notes/relnotes-2023.10.20260120.html

========================================================================================================================================================

Installed:
  mariadb-connector-c-3.3.10-1.amzn2023.0.1.x86_64  mariadb-connector-c-config-3.3.10-1.amzn2023.0.1.noarch mariadb105-3:10.5.29-1.amzn2023.0.1.x86_64
  mariadb105-common-3:10.5.29-1.amzn2023.0.1.x86_64 perl-Sys-Hostname-1.23-477.amzn2023.0.7.x86_64         

Complete!
sh-5.2$ mysql -h lab-mysql.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com -P 3306 -u admin -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 51
Server version: 8.0.44 Source distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> 
MySQL [(none)]> exit
Bye


