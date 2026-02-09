1) Prove EC2 is private (no public IP)
```
aws ec2 describe-instances \
  --instance-ids i-00365a3dfb8cd5e93 \
  --region ap-northeast-1 \
  --query "Reservations[].Instances[].PublicIpAddress"
```

Expected: null

$aws ec2 describe-instances \
>   --instance-ids i-00365a3dfb8cd5e93 \
>   --region ap-northeast-1 \
>   --query "Reservations[].Instances[].PublicIpAddress"
[]


2) Prove VPC endpoints exist
```
aws ec2 describe-vpc-endpoints \
  --region ap-northeast-1 \
  --filters "Name=vpc-id,Values=vpc-0d294ac5ee1adb6e9" \
  --query "VpcEndpoints[].ServiceName"
```

Expected includes:

ssm, ec2messages, ssmmessages, logs, secretsmanager, s3

 $aws ec2 describe-vpc-endpoints \
>   --region ap-northeast-1 \
>   --filters "Name=vpc-id,Values=vpc-0d294ac5ee1adb6e9" \
>   --query "VpcEndpoints[].ServiceName"
[
    "com.amazonaws.ap-northeast-1.s3",
    "com.amazonaws.ap-northeast-1.logs",
    "com.amazonaws.ap-northeast-1.ec2messages",
    "com.amazonaws.ap-northeast-1.ssm",
    "com.amazonaws.ap-northeast-1.secretsmanager",
    "com.amazonaws.ap-northeast-1.ssmmessages"
]



3) Prove Session Manager works (no SSH)
```
aws ssm describe-instance-information \
  --region ap-northeast-1 \
  --query "InstanceInformationList[].InstanceId"
```

Expected: instance ID appears

$aws ssm describe-instance-information \
>   --region ap-northeast-1 \
>   --query "InstanceInformationList[].InstanceId"
[
    "i-00365a3dfb8cd5e93"
]

4) From SSM session: read Parameter Store + Secrets Manager
```
aws ssm get-parameter --name /lab/db/endpoint   --region ap-northeast-1 
```
$aws ssm get-parameter --name /lab/db/endpoint   --region ap-northeast-1 
{
    "Parameter": {
        "Name": "/lab/db/endpoint",
        "Type": "String",
        "Value": "lab-mysql.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com",
        "Version": 1,
        "LastModifiedDate": "2026-02-02T18:18:11.414000+01:00",
        "ARN": "arn:aws:ssm:ap-northeast-1:261519058382:parameter/lab/db/endpoint",
        "DataType": "text"
    }
}

```
aws secretsmanager get-secret-value   --region ap-northeast-1 --secret-id lab-1c/rds/mysql
```

 $aws secretsmanager get-secret-value   --region ap-northeast-1 --secret-id lab-1c/rds/mysql

{
    "ARN": "arn:aws:secretsmanager:ap-northeast-1:261519058382:secret:lab-1c/rds/mysql-JXTWyu",
    "Name": "lab-1c/rds/mysql",
    "VersionId": "terraform-20260202171624218000000001",
    "SecretString": "{\"db_name\":\"labdb\",\"engine\":\"mysql\",\"host\":\"lab-mysql.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com\",\"password\":\"StrongPassword123!\",\"port\":3306,\"username\":\"admin\"}",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2026-02-02T18:16:24.412000+01:00"
}


5) Prove CloudWatch logs path available
```
aws logs describe-log-streams \
  --region ap-northeast-1 \
  --log-group-name /aws/ec2/lab-rds-app
```

$ aws logs describe-log-streams \
>   --region ap-northeast-1 \
>   --log-group-name /aws/ec2/lab-rds-app
{
    "logStreams": [
        {
            "logStreamName": "i-00365a3dfb8cd5e93",
            "creationTime": 1770052881954,
            "firstEventTimestamp": 1770052876845,
            "lastEventTimestamp": 1770052876845,
            "lastIngestionTime": 1770052882113,
            "uploadSequenceToken": "49039859660512288391844069186474579251053119791274181025",
            "arn": "arn:aws:logs:ap-northeast-1:261519058382:log-group:/aws/ec2/lab-rds-app:log-stream:i-00365a3dfb8cd5e93",
            "storedBytes": 0
        }
    ]
}

## SSM Session Manager Access (No SSH)

Command:
aws ssm start-session --target i-00365a3dfb8cd5e93

Result:
Session established successfully.

Screenshot:
![ssm session from AWS CLI](/lab_1c_bonus_a/Images/bonus_a_ssm_session.png)

Notes:
No inbound SSH rules exist on the EC2 security group.
Instance has no public IP.
Instance still has NAT for now.
