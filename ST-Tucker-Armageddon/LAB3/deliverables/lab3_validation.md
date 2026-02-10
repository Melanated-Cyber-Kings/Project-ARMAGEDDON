# Global Architecture Validation --- devlab405.click

## Key Principles

-   PHI storage stays in Tokyo (RDS only in ap-northeast-1)
-   Compute can move, storage cannot
-   São Paulo is stateless and relies on Tokyo
-   CloudFront global URL: https://devlab405.click
-   WAF protects the edge
-   CloudTrail immutable history
-   SSM for EC2 access
-   TGW corridor between regions

## Data Residency Proof

### Tokyo RDS Exists

``` bash
aws rds describe-db-instances --region ap-northeast-1
```



{
    "DBInstances": [
        {
            "DBInstanceIdentifier": "terraform-20260209203037357900000005",
            "DBInstanceClass": "db.t3.micro",
            "Engine": "mariadb",
            "DBInstanceStatus": "available",
            "MasterUsername": "admin",
            "DBName": "medical_records",
            "Endpoint": {
                "Address": "terraform-20260209203037357900000005.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com",
                "Port": 3306,
                "HostedZoneId": "Z24O6O9L7SGTNB"
            },
            "AllocatedStorage": 20,
            "InstanceCreateTime": "2026-02-09T20:34:10.213000+00:00",
            "PreferredBackupWindow": "17:10-17:40",
            "BackupRetentionPeriod": 0,
            "DBSecurityGroups": [],
            "VpcSecurityGroups": [
                {
                    "VpcSecurityGroupId": "sg-0f5064ade89ecbb95",
                    "Status": "active"
                }
            ],
            "DBParameterGroups": [
                {
                    "DBParameterGroupName": "default.mariadb10.11",
                    "ParameterApplyStatus": "in-sync"
                }
            ],
            "AvailabilityZone": "ap-northeast-1c",
            "DBSubnetGroup": {
                "DBSubnetGroupName": "shinjuku-db-subnet-group",
                "DBSubnetGroupDescription": "Managed by Terraform",
                "VpcId": "vpc-0a47f80bdd3aa57cf",
                "SubnetGroupStatus": "Complete",
                "Subnets": [
                    {
                        "SubnetIdentifier": "subnet-0e104a35e41c28a5c",
                        "SubnetAvailabilityZone": {
                            "Name": "ap-northeast-1a"
                        },
                        "SubnetOutpost": {},
                        "SubnetStatus": "Active"
                    },
                    {
                        "SubnetIdentifier": "subnet-02659c17943e604c1",
                        "SubnetAvailabilityZone": {
                            "Name": "ap-northeast-1c"
                        },
                        "SubnetOutpost": {},
                        "SubnetStatus": "Active"
                    }
                ]
            },
            "PreferredMaintenanceWindow": "mon:19:34-mon:20:04",
            "UpgradeRolloutOrder": "second",
            "PendingModifiedValues": {},
            "MultiAZ": false,
            "EngineVersion": "10.11.15",
            "AutoMinorVersionUpgrade": true,
            "ReadReplicaDBInstanceIdentifiers": [],
            "LicenseModel": "general-public-license",
            "StorageThroughput": 0,
            "OptionGroupMemberships": [
                {
                    "OptionGroupName": "default:mariadb-10-11",
                    "Status": "in-sync"
                }
            ],
            "PubliclyAccessible": false,
            "StorageType": "gp2",
            "DbInstancePort": 0,
            "StorageEncrypted": false,
            "DbiResourceId": "db-RUJZHJKARM4C5A3YP5KDA3AKIY",
            "CACertificateIdentifier": "rds-ca-rsa2048-g1",
            "DomainMemberships": [],
            "CopyTagsToSnapshot": false,
            "MonitoringInterval": 0,
            "DBInstanceArn": "arn:aws:rds:ap-northeast-1:261519058382:db:terraform-20260209203037357900000005",
            "IAMDatabaseAuthenticationEnabled": false,
            "DatabaseInsightsMode": "standard",
            "PerformanceInsightsEnabled": false,
            "DeletionProtection": false,
            "AssociatedRoles": [],
            "TagList": [
                {
                    "Key": "Name",
                    "Value": "shinjuku-medical-rds"
                }
            ],
            "CustomerOwnedIpEnabled": false,
            "NetworkType": "IPV4",
            "ActivityStreamStatus": "stopped",
            "BackupTarget": "region",
            "CertificateDetails": {
                "CAIdentifier": "rds-ca-rsa2048-g1",
                "ValidTill": "2027-02-09T20:32:51+00:00"
            },
            "DedicatedLogVolume": false,
            "IsStorageConfigUpgradeAvailable": false
        }
    ]
}


### São Paulo Has No RDS

``` bash
aws rds describe-db-instances --region sa-east-1
```

{
    "DBInstances": []
}


### Application-Level Proof

``` bash
nc -vz <tokyo-rds-endpoint> 3306
```
$ nc -vz terraform-20260209203037357900000005.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com  3306
Connection to terraform-20260209203037357900000005.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com (10.101.2.183) 3306 port [tcp/mysql] succeeded!


## CloudFront Proof

``` bash
curl -I https://devlab405.click/api/public-feed
```

## WAF Proof

``` bash
aws logs tail /aws/waf/medical_global_waf --since 1h
```

## CloudTrail Proof

``` bash
aws cloudtrail lookup-events --max-results 20
```

{
    "Events": [
        {
            "EventId": "f41d7cc7-3588-4d2a-9248-c084d14478f7",
            "EventName": "DescribeLaunchTemplateVersions",
            "ReadOnly": "true",
            "EventTime": "2026-02-09T22:27:53+01:00",
            "EventSource": "ec2.amazonaws.com",
            "Username": "AutoScaling",
            "Resources": [
                {
                    "ResourceType": "AWS::EC2::LaunchTemplate",
                    "ResourceName": "lt-06c27243fce2571e5"
                }
            ],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4:AutoScaling\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling\",\"accountId\":\"261519058382\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForAutoScaling\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:27:03Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"autoscaling.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:27:53Z\",\"eventSource\":\"ec2.amazonaws.com\",\"eventName\":\"DescribeLaunchTemplateVersions\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"autoscaling.amazonaws.com\",\"userAgent\":\"autoscaling.amazonaws.com\",\"requestParameters\":{\"DescribeLaunchTemplateVersionsRequest\":{\"LaunchTemplateVersion\":{\"tag\":1,\"content\":\"$Latest\"},\"LaunchTemplateId\":\"lt-06c27243fce2571e5\"}},\"responseElements\":null,\"requestID\":\"6b201bb2-987e-48bc-8256-c48af8a5fdcd\",\"eventID\":\"f41d7cc7-3588-4d2a-9248-c084d14478f7\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "5abc9a56-153c-4ef0-89a6-fd02790dc178",
            "EventName": "DescribeInstanceStatus",
            "ReadOnly": "true",
            "EventTime": "2026-02-09T22:27:45+01:00",
            "EventSource": "ec2.amazonaws.com",
            "Username": "AutoScaling",
            "Resources": [],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4:AutoScaling\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling\",\"accountId\":\"261519058382\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForAutoScaling\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:03:52Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"autoscaling.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:27:45Z\",\"eventSource\":\"ec2.amazonaws.com\",\"eventName\":\"DescribeInstanceStatus\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"autoscaling.amazonaws.com\",\"userAgent\":\"autoscaling.amazonaws.com\",\"requestParameters\":{\"instancesSet\":{\"items\":[{\"instanceId\":\"i-0e683f0d797a845ab\"},{\"instanceId\":\"i-0991734feedffa734\"}]},\"filterSet\":{},\"includeAllInstances\":true,\"ignoreManagedInstancesVisibilityConfiguration\":false},\"responseElements\":null,\"requestID\":\"bee76e83-51bd-49bc-a45c-0448a1c79f23\",\"eventID\":\"5abc9a56-153c-4ef0-89a6-fd02790dc178\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "ccc27cc7-1f93-44a5-a259-57357468671f",
            "EventName": "DescribeTargetHealth",
            "ReadOnly": "true",
            "AccessKeyId": "ASIATZY6AEXHNDKSMOIL",
            "EventTime": "2026-02-09T22:27:45+01:00",
            "EventSource": "elasticloadbalancing.amazonaws.com",
            "Username": "AutoScaling",
            "Resources": [],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4:AutoScaling\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling\",\"accountId\":\"261519058382\",\"accessKeyId\":\"ASIATZY6AEXHNDKSMOIL\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForAutoScaling\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:03:52Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"autoscaling.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:27:45Z\",\"eventSource\":\"elasticloadbalancing.amazonaws.com\",\"eventName\":\"DescribeTargetHealth\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"autoscaling.amazonaws.com\",\"userAgent\":\"autoscaling.amazonaws.com\",\"requestParameters\":{\"targetGroupArn\":\"arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:targetgroup/shinjuku-tg/a770c60c3b857577\",\"targets\":[]},\"responseElements\":null,\"requestID\":\"c2707b0a-0d44-4423-8b87-f7786f17198a\",\"eventID\":\"ccc27cc7-1f93-44a5-a259-57357468671f\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"apiVersion\":\"2015-12-01\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "778c3b18-b12d-424e-82ed-e8442ffa9138",
            "EventName": "DescribeLaunchTemplateVersions",
            "ReadOnly": "true",
            "EventTime": "2026-02-09T22:27:43+01:00",
            "EventSource": "ec2.amazonaws.com",
            "Username": "AutoScaling",
            "Resources": [
                {
                    "ResourceType": "AWS::EC2::LaunchTemplate",
                    "ResourceName": "lt-06c27243fce2571e5"
                }
            ],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4:AutoScaling\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling\",\"accountId\":\"261519058382\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForAutoScaling\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:27:03Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"autoscaling.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:27:43Z\",\"eventSource\":\"ec2.amazonaws.com\",\"eventName\":\"DescribeLaunchTemplateVersions\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"autoscaling.amazonaws.com\",\"userAgent\":\"autoscaling.amazonaws.com\",\"requestParameters\":{\"DescribeLaunchTemplateVersionsRequest\":{\"LaunchTemplateVersion\":{\"tag\":1,\"content\":\"$Latest\"},\"LaunchTemplateId\":\"lt-06c27243fce2571e5\"}},\"responseElements\":null,\"requestID\":\"690d6853-bc20-43f3-8b25-e18fef0f8f54\",\"eventID\":\"778c3b18-b12d-424e-82ed-e8442ffa9138\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "f3cf0407-f674-4fe8-9aec-9dc9cc2c7d66",
            "EventName": "DescribeLaunchTemplateVersions",
            "ReadOnly": "true",
            "EventTime": "2026-02-09T22:27:33+01:00",
            "EventSource": "ec2.amazonaws.com",
            "Username": "AutoScaling",
            "Resources": [
                {
                    "ResourceType": "AWS::EC2::LaunchTemplate",
                    "ResourceName": "lt-06c27243fce2571e5"
                }
            ],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4:AutoScaling\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling\",\"accountId\":\"261519058382\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForAutoScaling\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:27:03Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"autoscaling.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:27:33Z\",\"eventSource\":\"ec2.amazonaws.com\",\"eventName\":\"DescribeLaunchTemplateVersions\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"autoscaling.amazonaws.com\",\"userAgent\":\"autoscaling.amazonaws.com\",\"requestParameters\":{\"DescribeLaunchTemplateVersionsRequest\":{\"LaunchTemplateVersion\":{\"tag\":1,\"content\":\"$Latest\"},\"LaunchTemplateId\":\"lt-06c27243fce2571e5\"}},\"responseElements\":null,\"requestID\":\"9a991ea8-2614-403f-b995-a75dd5400543\",\"eventID\":\"f3cf0407-f674-4fe8-9aec-9dc9cc2c7d66\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "d0dbf9b6-e797-4e4f-9630-c108d2d4c653",
            "EventName": "DescribeLaunchTemplateVersions",
            "ReadOnly": "true",
            "EventTime": "2026-02-09T22:27:23+01:00",
            "EventSource": "ec2.amazonaws.com",
            "Username": "AutoScaling",
            "Resources": [
                {
                    "ResourceType": "AWS::EC2::LaunchTemplate",
                    "ResourceName": "lt-06c27243fce2571e5"
                }
            ],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4:AutoScaling\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling\",\"accountId\":\"261519058382\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForAutoScaling\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:27:03Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"autoscaling.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:27:23Z\",\"eventSource\":\"ec2.amazonaws.com\",\"eventName\":\"DescribeLaunchTemplateVersions\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"autoscaling.amazonaws.com\",\"userAgent\":\"autoscaling.amazonaws.com\",\"requestParameters\":{\"DescribeLaunchTemplateVersionsRequest\":{\"LaunchTemplateVersion\":{\"tag\":1,\"content\":\"$Latest\"},\"LaunchTemplateId\":\"lt-06c27243fce2571e5\"}},\"responseElements\":null,\"requestID\":\"b527b5ca-3029-49b8-8d89-ba0345fd63ae\",\"eventID\":\"d0dbf9b6-e797-4e4f-9630-c108d2d4c653\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "b8d46695-fcd4-48d2-a710-6587fdb552a8",
            "EventName": "DescribeDBInstances",
            "ReadOnly": "true",
            "AccessKeyId": "AKIATZY6AEXHPMT4IXNH",
            "EventTime": "2026-02-09T22:27:15+01:00",
            "EventSource": "rds.amazonaws.com",
            "Username": "mrhijinx300",
            "Resources": [],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"IAMUser\",\"principalId\":\"AIDATZY6AEXHKMBPSQIBZ\",\"arn\":\"arn:aws:iam::261519058382:user/mrhijinx300\",\"accountId\":\"261519058382\",\"accessKeyId\":\"AKIATZY6AEXHPMT4IXNH\",\"userName\":\"mrhijinx300\"},\"eventTime\":\"2026-02-09T21:27:15Z\",\"eventSource\":\"rds.amazonaws.com\",\"eventName\":\"DescribeDBInstances\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"178.24.86.77\",\"userAgent\":\"aws-cli/2.33.17 md/awscrt#0.31.1 ua/2.1 os/macos#25.2.0 md/arch#arm64 lang/python#3.13.12 md/pyimpl#CPython m/Z,n,E,C,b cfg/retry-mode#standard md/installer#source sid/5bdfd180e4c5 md/prompt#off md/command#rds.describe-db-instances\",\"requestParameters\":null,\"responseElements\":null,\"requestID\":\"85ead1a1-e9f0-439a-b890-f7a46af8a261\",\"eventID\":\"b8d46695-fcd4-48d2-a710-6587fdb552a8\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\",\"tlsDetails\":{\"tlsVersion\":\"TLSv1.3\",\"cipherSuite\":\"TLS_AES_128_GCM_SHA256\",\"clientProvidedHostHeader\":\"rds.ap-northeast-1.amazonaws.com\"}}"
        },
        {
            "EventId": "916d96c4-2f67-42ed-adb0-f1fe3a6e0510",
            "EventName": "DescribeLaunchTemplateVersions",
            "ReadOnly": "true",
            "EventTime": "2026-02-09T22:27:13+01:00",
            "EventSource": "ec2.amazonaws.com",
            "Username": "AutoScaling",
            "Resources": [
                {
                    "ResourceType": "AWS::EC2::LaunchTemplate",
                    "ResourceName": "lt-06c27243fce2571e5"
                }
            ],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4:AutoScaling\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling\",\"accountId\":\"261519058382\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForAutoScaling\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:27:03Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"autoscaling.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:27:13Z\",\"eventSource\":\"ec2.amazonaws.com\",\"eventName\":\"DescribeLaunchTemplateVersions\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"autoscaling.amazonaws.com\",\"userAgent\":\"autoscaling.amazonaws.com\",\"requestParameters\":{\"DescribeLaunchTemplateVersionsRequest\":{\"LaunchTemplateVersion\":{\"tag\":1,\"content\":\"$Latest\"},\"LaunchTemplateId\":\"lt-06c27243fce2571e5\"}},\"responseElements\":null,\"requestID\":\"af0d38cb-435a-43a1-9627-64575e1159b3\",\"eventID\":\"916d96c4-2f67-42ed-adb0-f1fe3a6e0510\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "3d66d270-9a3c-3693-82ed-4f2230bfa68f",
            "EventName": "AssumeRole",
            "ReadOnly": "true",
            "EventTime": "2026-02-09T22:27:03+01:00",
            "EventSource": "sts.amazonaws.com",
            "Resources": [
                {
                    "ResourceType": "AWS::IAM::AccessKey",
                    "ResourceName": "ASIATZY6AEXHK4TDFY3E"
                },
                {
                    "ResourceType": "AWS::STS::AssumedRole",
                    "ResourceName": "AROATZY6AEXHFRL3TMWE4:AutoScaling"
                },
                {
                    "ResourceType": "AWS::STS::AssumedRole",
                    "ResourceName": "AutoScaling"
                },
                {
                    "ResourceType": "AWS::STS::AssumedRole",
                    "ResourceName": "arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling"
                },
                {
                    "ResourceType": "AWS::IAM::Role",
                    "ResourceName": "arn:aws:iam::261519058382:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
                }
            ],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AWSService\",\"invokedBy\":\"autoscaling.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:27:03Z\",\"eventSource\":\"sts.amazonaws.com\",\"eventName\":\"AssumeRole\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"autoscaling.amazonaws.com\",\"userAgent\":\"autoscaling.amazonaws.com\",\"requestParameters\":{\"roleArn\":\"arn:aws:iam::261519058382:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\",\"roleSessionName\":\"AutoScaling\",\"durationSeconds\":1800},\"responseElements\":{\"credentials\":{\"accessKeyId\":\"ASIATZY6AEXHK4TDFY3E\",\"sessionToken\":\"IQoJb3JpZ2luX2VjEM3//////////wEaDmFwLW5vcnRoZWFzdC0xIkgwRgIhAI0rYq7jFE4RD+7eydUUZAYOC8wSwB0i0P4wm5JFOvXDAiEA5Qxa0bs2wDF99ihrooJ5kB5d/Rl9btQfCCpuvrrSzvYq4wIIl///////////ARAAGgwyNjE1MTkwNTgzODIiDJQhHoCKmCXxg+fahiq3Avo+kCKc+Qg9DuIHGjvs/lt7y2h85YtGoaI1hvzvxzDiINJvh4a68hMMkEw+aIMaRmkpZUh7md6z5GrKd4FwMLuSiklmGHjYsj679kLU/m8z/8KzLowgI7TBGzUf0TUM5jwOXeVsV+jCS2o0JqhOsYIVgdTl3CIIB4zxd+IJuCP4QJKuuxVbw0ROtH7qdkCdEH9r/xQ6mVaAjvWY3Tw7RZHIvLlYIXJkM/+TuS7Drs79BEW81DkzctrJY7f6ibVd1/+ynIIxWSZLCNxhYG8OYau/5KxmXRaoe0QklT7WHsap8bZ6LpiBjjT7xpUWcDLr0t/oJa5Lef0A+hcdiERmJgykPkPUu3XzVnnrpzORfsjLLjXWUhmeeEz7L0XVfF64o/afkTMaAvw0o2sQH7LBG8wjs/BpIEyTMKeiqcwGOrwBtufgSzJ8jz6GYYDimIJAbvu06TX0cAaLjjXepN/AoV40UT524BDHJRxD+Vyole9GRdJCvAY+eVZYgPE243trTPvHWN01UKTAcEJA78udKRauDKR9q0mYkJzKH1/YI1LlGvKMsveQ7KqreUF0u65C/Ds0FttOH2ORgmPFe0tRvKxYVAe0bYKFHKg8oQt4jVIKbQu1TmBh7oCrof9Yfg5PD8RiGbcUKWkjLHnvnxPANoTJ+qygZRn0uxSRb+c=\",\"expiration\":\"Feb 9, 2026, 9:57:03 PM\"},\"assumedRoleUser\":{\"assumedRoleId\":\"AROATZY6AEXHFRL3TMWE4:AutoScaling\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling\"}},\"additionalEventData\":{\"ExtendedRequestId\":\"MTphcC1ub3J0aGVhc3QtMTpTOjE3NzA2NzI0MjM4NDI6Ujp3YTFEaU10MA==\"},\"requestID\":\"d1c0ce6f-b5ff-415a-aa8e-9c7dd4ce8a2f\",\"eventID\":\"3d66d270-9a3c-3693-82ed-4f2230bfa68f\",\"readOnly\":true,\"resources\":[{\"accountId\":\"261519058382\",\"type\":\"AWS::IAM::Role\",\"ARN\":\"arn:aws:iam::261519058382:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\"}],\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"sharedEventID\":\"aa3bf71e-7679-41a2-861f-811b8b638ac9\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "4b37995d-e803-4878-a257-1bbf2f3b3820",
            "EventName": "DescribeLaunchTemplateVersions",
            "ReadOnly": "true",
            "EventTime": "2026-02-09T22:27:03+01:00",
            "EventSource": "ec2.amazonaws.com",
            "Username": "AutoScaling",
            "Resources": [
                {
                    "ResourceType": "AWS::EC2::LaunchTemplate",
                    "ResourceName": "lt-06c27243fce2571e5"
                }
            ],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4:AutoScaling\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling\",\"accountId\":\"261519058382\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForAutoScaling\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:27:03Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"autoscaling.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:27:03Z\",\"eventSource\":\"ec2.amazonaws.com\",\"eventName\":\"DescribeLaunchTemplateVersions\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"autoscaling.amazonaws.com\",\"userAgent\":\"autoscaling.amazonaws.com\",\"requestParameters\":{\"DescribeLaunchTemplateVersionsRequest\":{\"LaunchTemplateVersion\":{\"tag\":1,\"content\":\"$Latest\"},\"LaunchTemplateId\":\"lt-06c27243fce2571e5\"}},\"responseElements\":null,\"requestID\":\"2a5e0847-b2b7-4afd-b8b1-a9524c72add8\",\"eventID\":\"4b37995d-e803-4878-a257-1bbf2f3b3820\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "3981c562-8da1-4242-b6aa-99d7c2a4481b",
            "EventName": "DescribeLaunchTemplateVersions",
            "ReadOnly": "true",
            "EventTime": "2026-02-09T22:26:53+01:00",
            "EventSource": "ec2.amazonaws.com",
            "Username": "AutoScaling",
            "Resources": [
                {
                    "ResourceType": "AWS::EC2::LaunchTemplate",
                    "ResourceName": "lt-06c27243fce2571e5"
                }
            ],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4:AutoScaling\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling\",\"accountId\":\"261519058382\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForAutoScaling\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:01:57Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"autoscaling.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:26:53Z\",\"eventSource\":\"ec2.amazonaws.com\",\"eventName\":\"DescribeLaunchTemplateVersions\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"autoscaling.amazonaws.com\",\"userAgent\":\"autoscaling.amazonaws.com\",\"requestParameters\":{\"DescribeLaunchTemplateVersionsRequest\":{\"LaunchTemplateVersion\":{\"tag\":1,\"content\":\"$Latest\"},\"LaunchTemplateId\":\"lt-06c27243fce2571e5\"}},\"responseElements\":null,\"requestID\":\"74f1126e-e9e3-454f-b205-5cfe65b6902e\",\"eventID\":\"3981c562-8da1-4242-b6aa-99d7c2a4481b\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "06d16f59-b7d3-488c-b8c9-e6100dec3f4b",
            "EventName": "DescribeTags",
            "ReadOnly": "true",
            "AccessKeyId": "ASIATZY6AEXHOLLWEAD6",
            "EventTime": "2026-02-09T22:26:46+01:00",
            "EventSource": "elasticloadbalancing.amazonaws.com",
            "Username": "resource-explorer-2",
            "Resources": [],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHJAW4M5TH2:resource-explorer-2\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForResourceExplorer/resource-explorer-2\",\"accountId\":\"261519058382\",\"accessKeyId\":\"ASIATZY6AEXHOLLWEAD6\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHJAW4M5TH2\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/resource-explorer-2.amazonaws.com/AWSServiceRoleForResourceExplorer\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForResourceExplorer\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:26:46Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"resource-explorer-2.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:26:46Z\",\"eventSource\":\"elasticloadbalancing.amazonaws.com\",\"eventName\":\"DescribeTags\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"resource-explorer-2.amazonaws.com\",\"userAgent\":\"resource-explorer-2.amazonaws.com\",\"requestParameters\":{\"resourceArns\":[\"arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:targetgroup/shinjuku-tg/a770c60c3b857577\"]},\"responseElements\":null,\"requestID\":\"a64f1e9f-8a43-4250-ad8c-cc0bf0f31852\",\"eventID\":\"06d16f59-b7d3-488c-b8c9-e6100dec3f4b\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"apiVersion\":\"2015-12-01\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "2f695355-292c-4b42-80c0-fe2d865e75ae",
            "EventName": "DescribeTargetGroupAttributes",
            "ReadOnly": "true",
            "AccessKeyId": "ASIATZY6AEXHOLLWEAD6",
            "EventTime": "2026-02-09T22:26:46+01:00",
            "EventSource": "elasticloadbalancing.amazonaws.com",
            "Username": "resource-explorer-2",
            "Resources": [],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHJAW4M5TH2:resource-explorer-2\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForResourceExplorer/resource-explorer-2\",\"accountId\":\"261519058382\",\"accessKeyId\":\"ASIATZY6AEXHOLLWEAD6\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHJAW4M5TH2\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/resource-explorer-2.amazonaws.com/AWSServiceRoleForResourceExplorer\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForResourceExplorer\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:26:46Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"resource-explorer-2.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:26:46Z\",\"eventSource\":\"elasticloadbalancing.amazonaws.com\",\"eventName\":\"DescribeTargetGroupAttributes\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"resource-explorer-2.amazonaws.com\",\"userAgent\":\"resource-explorer-2.amazonaws.com\",\"requestParameters\":{\"targetGroupArn\":\"arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:targetgroup/shinjuku-tg/a770c60c3b857577\"},\"responseElements\":null,\"requestID\":\"3c96846c-3d54-482c-9c26-4e5bebb502ff\",\"eventID\":\"2f695355-292c-4b42-80c0-fe2d865e75ae\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"apiVersion\":\"2015-12-01\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "522949b1-b634-31d4-b384-b7abbcec768e",
            "EventName": "AssumeRole",
            "ReadOnly": "true",
            "EventTime": "2026-02-09T22:26:46+01:00",
            "EventSource": "sts.amazonaws.com",
            "Resources": [
                {
                    "ResourceType": "AWS::IAM::AccessKey",
                    "ResourceName": "ASIATZY6AEXHDM4IUL5K"
                },
                {
                    "ResourceType": "AWS::STS::AssumedRole",
                    "ResourceName": "resource-explorer-2"
                },
                {
                    "ResourceType": "AWS::STS::AssumedRole",
                    "ResourceName": "AROATZY6AEXHJAW4M5TH2:resource-explorer-2"
                },
                {
                    "ResourceType": "AWS::STS::AssumedRole",
                    "ResourceName": "arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForResourceExplorer/resource-explorer-2"
                },
                {
                    "ResourceType": "AWS::IAM::Role",
                    "ResourceName": "arn:aws:iam::261519058382:role/aws-service-role/resource-explorer-2.amazonaws.com/AWSServiceRoleForResourceExplorer"
                }
            ],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AWSService\",\"invokedBy\":\"resource-explorer-2.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:26:46Z\",\"eventSource\":\"sts.amazonaws.com\",\"eventName\":\"AssumeRole\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"resource-explorer-2.amazonaws.com\",\"userAgent\":\"resource-explorer-2.amazonaws.com\",\"requestParameters\":{\"roleArn\":\"arn:aws:iam::261519058382:role/aws-service-role/resource-explorer-2.amazonaws.com/AWSServiceRoleForResourceExplorer\",\"roleSessionName\":\"resource-explorer-2\"},\"responseElements\":{\"credentials\":{\"accessKeyId\":\"ASIATZY6AEXHDM4IUL5K\",\"sessionToken\":\"IQoJb3JpZ2luX2VjEM3//////////wEaDmFwLW5vcnRoZWFzdC0xIkgwRgIhAPvevOuf6gAC6HPDmUloWAR5Hwzbvxf1dWgimyE3zuIwAiEAgNnHzO9XutewCB/FYokxP0Z1nLoz9PfFTFpZWDeYuOkq+wIIl///////////ARAAGgwyNjE1MTkwNTgzODIiDJKOiQsEA6sakgvc+CrPAtfIadXnNeaeO+dII9AAo2EDSKYumo+BNXNKl9w8AefUep8vkzElpXPgBBQzJlpkLqJeedphrIpQLIv+bqvT6XTKSp1/Jxw8SoA6E4xqQjYpsd/KJ7VhkebrSkzmwmx7VBFrnNY9UcuGK1oXy+YcnVhUZ0LY3KvM1gKGt6ieixT5so5RGUUKKMDbKpODnGJCUHgdakkUZM3GqA5ujSucTjYyapEz06H+OEYrmBfZoWSIXncHwS/qjc0JeSE4b4Jb47JUGhSMEMaF43RyjLJe26oabF9CbE791FOkJzXXzjjpcVf8o08nXdgIvyslyd8eIWh18fF9F8fpyRSDzt80uZ8rI6F4ytfjUzcSycGwoo1jGhjbbQtO1Bi+GuRPGaq6s0QM3OciXwtG00WxrvlqGwJa3NRiroCikuBI6maGDrdW7wNgqXFPlW+Wvd8mmfBHMJaiqcwGOrwB9NLd/O0BMiBLFeUcxMw2qhsap1sjaYxBAfrrrtAWySEfKTcwlNFVMaWI6Hdi4zjRw8l9mtWp+sM4wLRsoxKVaoKw6Af0yLdx0QRjli/R3Z3x793N0YOCg0RAu3LBpzJR+cGTB9x0Y7jByiPpEIdXv7UzyaTkrOTy/tZPBIAeGulDG3mJttIkBwE0fowk6yN1AAq9O61qIgkrjh3oN3WiIYIC52YxfWKcnfKTlkAfQNYxt2yGnv1891XVjgQ=\",\"expiration\":\"Feb 9, 2026, 10:26:46 PM\"},\"assumedRoleUser\":{\"assumedRoleId\":\"AROATZY6AEXHJAW4M5TH2:resource-explorer-2\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForResourceExplorer/resource-explorer-2\"}},\"additionalEventData\":{\"ExtendedRequestId\":\"MTphcC1ub3J0aGVhc3QtMTpTOjE3NzA2NzI0MDY1NTk6UjpDY2FyaURxag==\"},\"requestID\":\"468dfc13-df5e-43e6-a997-92093fef8ed5\",\"eventID\":\"522949b1-b634-31d4-b384-b7abbcec768e\",\"readOnly\":true,\"resources\":[{\"accountId\":\"261519058382\",\"type\":\"AWS::IAM::Role\",\"ARN\":\"arn:aws:iam::261519058382:role/aws-service-role/resource-explorer-2.amazonaws.com/AWSServiceRoleForResourceExplorer\"}],\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"sharedEventID\":\"a62dae39-1aa7-4782-8a09-b58c9a571179\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "b90265a9-e815-4b00-a5a2-0ac0a002f73e",
            "EventName": "DescribeTargetHealth",
            "ReadOnly": "true",
            "AccessKeyId": "ASIATZY6AEXHOLLWEAD6",
            "EventTime": "2026-02-09T22:26:46+01:00",
            "EventSource": "elasticloadbalancing.amazonaws.com",
            "Username": "resource-explorer-2",
            "Resources": [],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHJAW4M5TH2:resource-explorer-2\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForResourceExplorer/resource-explorer-2\",\"accountId\":\"261519058382\",\"accessKeyId\":\"ASIATZY6AEXHOLLWEAD6\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHJAW4M5TH2\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/resource-explorer-2.amazonaws.com/AWSServiceRoleForResourceExplorer\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForResourceExplorer\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:26:46Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"resource-explorer-2.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:26:46Z\",\"eventSource\":\"elasticloadbalancing.amazonaws.com\",\"eventName\":\"DescribeTargetHealth\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"resource-explorer-2.amazonaws.com\",\"userAgent\":\"resource-explorer-2.amazonaws.com\",\"requestParameters\":{\"targetGroupArn\":\"arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:targetgroup/shinjuku-tg/a770c60c3b857577\"},\"responseElements\":null,\"requestID\":\"5ae8eb46-3a52-4ffd-8732-fcc5595fe2d2\",\"eventID\":\"b90265a9-e815-4b00-a5a2-0ac0a002f73e\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"apiVersion\":\"2015-12-01\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "bc33604e-9b32-4820-866c-44a3c768a903",
            "EventName": "DescribeTargetGroups",
            "ReadOnly": "true",
            "AccessKeyId": "ASIATZY6AEXHOLLWEAD6",
            "EventTime": "2026-02-09T22:26:46+01:00",
            "EventSource": "elasticloadbalancing.amazonaws.com",
            "Username": "resource-explorer-2",
            "Resources": [],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHJAW4M5TH2:resource-explorer-2\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForResourceExplorer/resource-explorer-2\",\"accountId\":\"261519058382\",\"accessKeyId\":\"ASIATZY6AEXHOLLWEAD6\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHJAW4M5TH2\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/resource-explorer-2.amazonaws.com/AWSServiceRoleForResourceExplorer\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForResourceExplorer\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:26:46Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"resource-explorer-2.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:26:46Z\",\"eventSource\":\"elasticloadbalancing.amazonaws.com\",\"eventName\":\"DescribeTargetGroups\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"resource-explorer-2.amazonaws.com\",\"userAgent\":\"resource-explorer-2.amazonaws.com\",\"requestParameters\":{\"targetGroupArns\":[\"arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:targetgroup/shinjuku-tg/a770c60c3b857577\"]},\"responseElements\":null,\"requestID\":\"ed30cb7a-1fe8-4e5d-a3bd-658ea16be712\",\"eventID\":\"bc33604e-9b32-4820-866c-44a3c768a903\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"apiVersion\":\"2015-12-01\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "e315f7ae-7d77-4055-85cd-728dc0eb6d53",
            "EventName": "GetResource",
            "ReadOnly": "true",
            "AccessKeyId": "ASIATZY6AEXHDM4IUL5K",
            "EventTime": "2026-02-09T22:26:46+01:00",
            "EventSource": "cloudcontrolapi.amazonaws.com",
            "Username": "resource-explorer-2",
            "Resources": [],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHJAW4M5TH2:resource-explorer-2\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForResourceExplorer/resource-explorer-2\",\"accountId\":\"261519058382\",\"accessKeyId\":\"ASIATZY6AEXHDM4IUL5K\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHJAW4M5TH2\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/resource-explorer-2.amazonaws.com/AWSServiceRoleForResourceExplorer\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForResourceExplorer\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:26:46Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"resource-explorer-2.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:26:46Z\",\"eventSource\":\"cloudcontrolapi.amazonaws.com\",\"eventName\":\"GetResource\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"resource-explorer-2.amazonaws.com\",\"userAgent\":\"resource-explorer-2.amazonaws.com\",\"requestParameters\":{\"typeName\":\"AWS::ElasticLoadBalancingV2::TargetGroup\",\"identifier\":\"arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:targetgroup/shinjuku-tg/a770c60c3b857577\"},\"responseElements\":null,\"requestID\":\"755d323c-0842-497d-85ba-3329448ddf3a\",\"eventID\":\"e315f7ae-7d77-4055-85cd-728dc0eb6d53\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "449ce0b1-e839-446f-8ad1-4957dc5d5be9",
            "EventName": "DescribeLaunchTemplateVersions",
            "ReadOnly": "true",
            "EventTime": "2026-02-09T22:26:43+01:00",
            "EventSource": "ec2.amazonaws.com",
            "Username": "AutoScaling",
            "Resources": [
                {
                    "ResourceType": "AWS::EC2::LaunchTemplate",
                    "ResourceName": "lt-06c27243fce2571e5"
                }
            ],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4:AutoScaling\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling\",\"accountId\":\"261519058382\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForAutoScaling\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:01:57Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"autoscaling.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:26:43Z\",\"eventSource\":\"ec2.amazonaws.com\",\"eventName\":\"DescribeLaunchTemplateVersions\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"autoscaling.amazonaws.com\",\"userAgent\":\"autoscaling.amazonaws.com\",\"requestParameters\":{\"DescribeLaunchTemplateVersionsRequest\":{\"LaunchTemplateVersion\":{\"tag\":1,\"content\":\"$Latest\"},\"LaunchTemplateId\":\"lt-06c27243fce2571e5\"}},\"responseElements\":null,\"requestID\":\"c41f4494-d725-405d-8df5-6b48a9061124\",\"eventID\":\"449ce0b1-e839-446f-8ad1-4957dc5d5be9\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "6a621434-2e88-4e31-bb34-312703ec09ca",
            "EventName": "DescribeLaunchTemplateVersions",
            "ReadOnly": "true",
            "EventTime": "2026-02-09T22:26:33+01:00",
            "EventSource": "ec2.amazonaws.com",
            "Username": "AutoScaling",
            "Resources": [
                {
                    "ResourceType": "AWS::EC2::LaunchTemplate",
                    "ResourceName": "lt-06c27243fce2571e5"
                }
            ],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4:AutoScaling\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling\",\"accountId\":\"261519058382\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForAutoScaling\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:01:57Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"autoscaling.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:26:33Z\",\"eventSource\":\"ec2.amazonaws.com\",\"eventName\":\"DescribeLaunchTemplateVersions\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"autoscaling.amazonaws.com\",\"userAgent\":\"autoscaling.amazonaws.com\",\"requestParameters\":{\"DescribeLaunchTemplateVersionsRequest\":{\"LaunchTemplateVersion\":{\"tag\":1,\"content\":\"$Latest\"},\"LaunchTemplateId\":\"lt-06c27243fce2571e5\"}},\"responseElements\":null,\"requestID\":\"b4a5262b-a438-4359-afa8-1efe68cd4667\",\"eventID\":\"6a621434-2e88-4e31-bb34-312703ec09ca\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "62c2aba2-a430-48ba-a669-14e06fc2c0b1",
            "EventName": "DescribeLaunchTemplateVersions",
            "ReadOnly": "true",
            "EventTime": "2026-02-09T22:26:23+01:00",
            "EventSource": "ec2.amazonaws.com",
            "Username": "AutoScaling",
            "Resources": [
                {
                    "ResourceType": "AWS::EC2::LaunchTemplate",
                    "ResourceName": "lt-06c27243fce2571e5"
                }
            ],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4:AutoScaling\",\"arn\":\"arn:aws:sts::261519058382:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling\",\"accountId\":\"261519058382\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROATZY6AEXHFRL3TMWE4\",\"arn\":\"arn:aws:iam::261519058382:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\",\"accountId\":\"261519058382\",\"userName\":\"AWSServiceRoleForAutoScaling\"},\"attributes\":{\"creationDate\":\"2026-02-09T21:01:57Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"autoscaling.amazonaws.com\"},\"eventTime\":\"2026-02-09T21:26:23Z\",\"eventSource\":\"ec2.amazonaws.com\",\"eventName\":\"DescribeLaunchTemplateVersions\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"autoscaling.amazonaws.com\",\"userAgent\":\"autoscaling.amazonaws.com\",\"requestParameters\":{\"DescribeLaunchTemplateVersionsRequest\":{\"LaunchTemplateVersion\":{\"tag\":1,\"content\":\"$Latest\"},\"LaunchTemplateId\":\"lt-06c27243fce2571e5\"}},\"responseElements\":null,\"requestID\":\"2875d447-58fa-4bf3-8a6b-bdc6cd597880\",\"eventID\":\"62c2aba2-a430-48ba-a669-14e06fc2c0b1\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"261519058382\",\"eventCategory\":\"Management\"}"
        }
    ],
    "NextToken": "FtFJ4zDZg7bq6ompWQFu2ECRk/aBEqyBQPiuhXzl10x+Ho8EFMXWZelgUEKsZHEq"
}



## TGW Corridor Proof

``` bash
aws ec2 describe-transit-gateway-attachments --region ap-northeast-1
aws ec2 describe-transit-gateway-attachments --region sa-east-1
```

## Tokyo Region

``` bash{
    "TransitGatewayAttachments": [
        {
            "TransitGatewayAttachmentId": "tgw-attach-03dea7aa77ee8b081",
            "TransitGatewayId": "tgw-0fb0cd3cdb8197254",
            "TransitGatewayOwnerId": "261519058382",
            "ResourceOwnerId": "261519058382",
            "ResourceType": "peering",
            "ResourceId": "tgw-0412df64068b9d7a4",
            "State": "available",
            "Association": {
                "TransitGatewayRouteTableId": "tgw-rtb-0bb596430f10a1685",
                "State": "associated"
            },
            "CreationTime": "2026-02-09T20:32:19+00:00",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "shinjuku-to-liberdade-peer01"
                }
            ]
        },
        {
            "TransitGatewayAttachmentId": "tgw-attach-0672f2f2ba698b32d",
            "TransitGatewayId": "tgw-0b412463737c1d4fd",
            "TransitGatewayOwnerId": "261519058382",
            "ResourceOwnerId": "261519058382",
            "ResourceType": "vpc",
            "ResourceId": "vpc-0a8e7317a64c05c35",
            "State": "deleted",
            "CreationTime": "2026-02-09T18:05:36+00:00",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "tokyo-tgw-attach"
                }
            ]
        },
        {
            "TransitGatewayAttachmentId": "tgw-attach-038259d6c491a67f0",
            "TransitGatewayId": "tgw-0fb0cd3cdb8197254",
            "TransitGatewayOwnerId": "261519058382",
            "ResourceOwnerId": "261519058382",
            "ResourceType": "vpc",
            "ResourceId": "vpc-0a47f80bdd3aa57cf",
            "State": "available",
            "Association": {
                "TransitGatewayRouteTableId": "tgw-rtb-0bb596430f10a1685",
                "State": "associated"
            },
            "CreationTime": "2026-02-09T20:31:00+00:00",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "shinjuku-attach-tokyo-vpc01"
                }
            ]
        }
    ]
}

# Sao Paulo Region

{
    "TransitGatewayAttachments": [
        {
            "TransitGatewayAttachmentId": "tgw-attach-03dea7aa77ee8b081",
            "TransitGatewayId": "tgw-0412df64068b9d7a4",
            "TransitGatewayOwnerId": "261519058382",
            "ResourceOwnerId": "261519058382",
            "ResourceType": "peering",
            "ResourceId": "tgw-0fb0cd3cdb8197254",
            "State": "available",
            "Association": {
                "TransitGatewayRouteTableId": "tgw-rtb-04392a2740ebfcc65",
                "State": "associated"
            },
            "CreationTime": "2026-02-09T20:32:49+00:00",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "liberdade-accept-peer01"
                }
            ]
        },
        {
            "TransitGatewayAttachmentId": "tgw-attach-055bfe5157463230b",
            "TransitGatewayId": "tgw-0412df64068b9d7a4",
            "TransitGatewayOwnerId": "261519058382",
            "ResourceOwnerId": "261519058382",
            "ResourceType": "vpc",
            "ResourceId": "vpc-05f299019cd1460f5",
            "State": "available",
            "Association": {
                "TransitGatewayRouteTableId": "tgw-rtb-04392a2740ebfcc65",
                "State": "associated"
            },
            "CreationTime": "2026-02-09T20:30:49+00:00",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "liberdade-attach-sp-vpc01"
                }
            ]
        }
    ]
}