Student verification (CLI) for Bonus-A
1) Prove EC2 is private (no public IP)
  aws ec2 describe-instances \
  --instance-ids i-0dd14322351a44cbb \
  --query "Reservations[].Instances[].PublicIpAddress"

[]

2) Prove VPC endpoints exist
  aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=vpc-09e7e6cc5ac255b7c" \
  --query "VpcEndpoints[].ServiceName"

[
    "com.amazonaws.ap-northeast-1.s3",
    "com.amazonaws.ap-northeast-1.ssmmessages",
    "com.amazonaws.ap-northeast-1.secretsmanager",
    "com.amazonaws.ap-northeast-1.ssm",
    "com.amazonaws.ap-northeast-1.ec2messages",
    "com.amazonaws.ap-northeast-1.logs",
    "com.amazonaws.ap-northeast-1.kms"
]

3) Prove Session Manager path works (no SSH)
aws ssm describe-instance-information \
  --query "InstanceInformationList[].InstanceId"

[
    "i-0dd14322351a44cbb"
]


4) Prove the instance can read both config stores
Run from SSM session:
  aws ssm get-parameter --name /lab/db/endpoint
  aws secretsmanager get-secret-value --secret-id armageddon-class-vii/rds/mysql-v2

 "Parameter": {
        "Name": "/lab/db/endpoint",
        "Type": "String",
        "Value": "armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com:3306",
        "Version": 1,
        "LastModifiedDate": "2026-02-09T18:35:58.660000+00:00",
        "ARN": "arn:aws:ssm:ap-northeast-1:420228061920:parameter/lab/db/endpoint",
        "DataType": "text"
    }

    
    "ARN": "arn:aws:secretsmanager:ap-northeast-1:420228061920:secret:armageddon-class-vii/rds/mysql-v2-FmS6x0",
    "Name": "armageddon-class-vii/rds/mysql-v2",
    "VersionId": "terraform-20260209224328057200000002",
    "SecretString": "{\"dbname\":\"labdb\",\"host\":\"armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com\",\"password\":\"Bigpimpin6\",\"port\":3306,\"username\":\"admin\"}",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2026-02-09T22:43:28.609000+00:00"
}

    

aws logs describe-log-streams \
    --log-group-name /aws/ec2/lab-rds-app
    --log-group-name /aws/ec2/lab-rds-app
{
    "logStreams": [
        {
            "logStreamName": "i-0761560d855121cae",
            "creationTime": 1770169893361,
            "firstEventTimestamp": 1770169888239,
            "lastEventTimestamp": 1770169893239,
            "lastIngestionTime": 1770169893535,
            "uploadSequenceToken": "49039859660667823249793079459839325267495913319887724351",
            "arn": "arn:aws:logs:ap-northeast-1:420228061920:log-group:/aws/ec2/lab-rds-app:log-stream:i-0761560d855121cae",
            "storedBytes": 0
        },
        {            "logStreamName": "i-0a27e1635461c49a7",
            "creationTime": 1770165310803,
            "firstEventTimestamp": 1770165305705,
            "lastEventTimestamp": 1770168363210,
            "lastIngestionTime": 1770168363551,
            "uploadSequenceToken": "49039859660665789552227176471112437985486524530883485564",
            "arn": "arn:aws:logs:ap-northeast-1:420228061920:log-group:/aws/ec2/lab-rds-app:log-stream:i-0a27e1635461c49a7",
            "storedBytes": 0
        }
    ]
}