Student verification (CLI) for Bonus-A
1) Prove EC2 is private (no public IP)
  aws ec2 describe-instances `
  --instance-ids i-042b0c597f59025ac `
  --query "Reservations[].Instances[].PublicIpAddress"

[]

2) Prove VPC endpoints exist
  aws ec2 describe-vpc-endpoints 
  --filters "Name=vpc-id,Values=vpc-07e52e6f899ae86ca" 
  --query "VpcEndpoints[].ServiceName"

[
    "com.amazonaws.ap-northeast-1.s3",
    "com.amazonaws.ap-northeast-1.secretsmanager",
    "com.amazonaws.ap-northeast-1.ssm",
    "com.amazonaws.ap-northeast-1.kms",
    "com.amazonaws.ap-northeast-1.ec2messages",
    "com.amazonaws.ap-northeast-1.ssmmessages",
    "com.amazonaws.ap-northeast-1.logs"
]

3) Prove Session Manager path works (no SSH)
aws ssm describe-instance-information `
  --query "InstanceInformationList[].InstanceId"

[
    "i-0c8390f19bff01693",
    "i-042b0c597f59025ac"
]

4) Prove the instance can read both config stores
Run from SSM session:
  aws ssm get-parameter --name /lab/db/endpoint
  aws secretsmanager get-secret-value --secret-id armageddon-class-vii/rds/mysql-v05

{
    {
    "Parameter": {
        "Name": "/lab/db/endpoint",
        "Type": "String",
        "Value": "armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com:3306",
        "Version": 4,
        "LastModifiedDate": "2026-03-04T21:38:26.932000+00:00",
        "ARN": "arn:aws:ssm:ap-northeast-1:420228061920:parameter/lab/db/endpoint",
        "DataType": "text"
    }
}

}
{
    "ARN": "arn:aws:secretsmanager:ap-northeast-1:420228061920:secret:armageddon-class-vii/rds/mysql-v05-qUF2tx",      
    "Name": "armageddon-class-vii/rds/mysql-v05",
    "VersionId": "terraform-20260304211230192200000002",
    "SecretString": "{\"dbname\":\"labdb\",\"host\":\"armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com\",\"password\":\"Bigpimpin6\",\"port\":3306,\"username\":\"admin\"}",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2026-03-04T21:12:30.740000+00:00"
}

aws logs describe-log-streams `
    --log-group-name /aws/ec2/armageddon-class-vii-rds-app

{
    "logStreams": [
        {
            "logStreamName": "i-042b0c597f59025ac",
            "creationTime": 1772660422868,
            "firstEventTimestamp": 1772660417802,
            "lastEventTimestamp": 1772661378558,
            "lastIngestionTime": 1772661379242,
            "uploadSequenceToken": "49039859663979575802635445485455050060241877890279804630",
            "arn": "arn:aws:logs:ap-northeast-1:420228061920:log-group:/aws/ec2/armageddon-class-vii-rds-app:log-stream:i-042b0c597f59025ac",
            "storedBytes": 0
        },
        {
            "logStreamName": "i-0c8390f19bff01693",
            "creationTime": 1772658812905,
            "firstEventTimestamp": 1772658807835,
            "lastEventTimestamp": 1772659135592,
            "lastIngestionTime": 1772659140622,
            "uploadSequenceToken": "49039859663976600166259521457083651296132919820010524189",
            "arn": "arn:aws:logs:ap-northeast-1:420228061920:log-group:/aws/ec2/armageddon-class-vii-rds-app:log-stream:i-0c8390f19bff01693",
            "storedBytes": 0
        }
    ]
}