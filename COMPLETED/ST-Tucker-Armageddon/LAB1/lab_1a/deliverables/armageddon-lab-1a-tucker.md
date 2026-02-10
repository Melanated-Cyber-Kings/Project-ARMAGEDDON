📌 Reviewer Note (Instructor Context)


The AWS deployment identifiers shown in this deliverable (such as VPC IDs, subnet IDs, security group IDs, instance IDs, ARNs, and RDS endpoints) were captured from a real lab run and may no longer exist after teardown.

These values are included for instructional and audit-review purposes only, to demonstrate expected output shapes, validation workflows, and security posture verification steps.

Instructors reviewing student submissions should focus on architecture, access paths, IAM scoping, security group relationships, encryption usage, and validation methodology rather than exact identifier matching.

# List all security groups in a region

aws ec2 describe-security-groups \
  --region ap-northeast-1 \
  --query "SecurityGroups[].{GroupId:GroupId,Name:GroupName,VpcId:VpcId}" \
  --output table

----------------------------------------------------------------------------
|                          DescribeSecurityGroups                          |
+----------------------+-------------------------+-------------------------+
|        GroupId       |          Name           |          VpcId          |
+----------------------+-------------------------+-------------------------+
|  sg-02bb0ebcada51e224|  rds-lab-1a             |  vpc-0ea1435ca15091d4f  |
|  sg-067b8ecdc3b5fbc26|  ec2-armageddon-lab-1a  |  vpc-0ea1435ca15091d4f  |
|  sg-05ce3c9a574373802|  default                |  vpc-0ea1435ca15091d4f  |
|  sg-03c102f59d7e0b79b|  default                |  vpc-0ad0fb7075d9225d0  |
+----------------------+-------------------------+-------------------------+

# Inspect ec2 security group (inbound & outbound rules)
aws ec2 describe-security-groups \
  --group-ids sg-067b8ecdc3b5fbc26 \
  --region ap-northeast-1 \
  --output json

  {
    "SecurityGroups": [
        {
            "GroupId": "sg-067b8ecdc3b5fbc26",
            "IpPermissionsEgress": [
                {
                    "IpProtocol": "-1",
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                }
            ],
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "sg-ec2-armageddon-lab-1a"
                }
            ],
            "VpcId": "vpc-0ea1435ca15091d4f",
            "SecurityGroupArn": "arn:aws:ec2:ap-northeast-1:<ACCOUNT_ID>:security-group/sg-067b8ecdc3b5fbc26",
            "OwnerId": "<ACCOUNT_ID>",
            "GroupName": "ec2-armageddon-lab-1a",
            "Description": "Security group for EC2",
            "IpPermissions": [
                {
                    "IpProtocol": "tcp",
                    "FromPort": 80,
                    "ToPort": 80,
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "Description": "Allow HTTP traffic",
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                },
                {
                    "IpProtocol": "tcp",
                    "FromPort": 22,
                    "ToPort": 22,
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                }
            ]
        }
    ]
}


# Verify which resources are using the security group EC2 instances

aws ec2 describe-instances \
  --filters Name=instance.group-id,Values=sg-067b8ecdc3b5fbc26 \
  --region ap-northeast-1 \
  --query "Reservations[].Instances[].InstanceId" \
  --output table

  -------------------------
|   DescribeInstances   |
+-----------------------+
|  i-01bb8e2d1d16a0455  |
+-----------------------+

# RDS instances

aws rds describe-db-instances \
  --region ap-northeast-1 \
  --query "DBInstances[?contains(VpcSecurityGroups[].VpcSecurityGroupId, 'sg-02bb0ebcada51e224')].DBInstanceIdentifier" \
  --output table

---------------------
|DescribeDBInstances|
+-------------------+
|  lab-mysql        |
+-------------------+

# List all RDS instances

aws rds describe-db-instances \
  --region ap-northeast-1 \
  --query "DBInstances[].{DB:DBInstanceIdentifier,Engine:Engine,Public:PubliclyAccessible,Vpc:DBSubnetGroup.VpcId}" \
  --output table

------------------------------------------------------------
|                    DescribeDBInstances                   |
+-----------+---------+---------+--------------------------+
|    DB     | Engine  | Public  |           Vpc            |
+-----------+---------+---------+--------------------------+
|  lab-mysql|  mysql  |  False  |  vpc-0ea1435ca15091d4f   |
+-----------+---------+---------+--------------------------+

# Inspect a specific RDS instance

aws rds describe-db-instances \
  --db-instance-identifier lab-mysql \
  --region ap-northeast-1 \
  --output json

  {
    "DBInstances": [
        {
            "DBInstanceIdentifier": "lab-mysql",
            "DBInstanceClass": "db.t3.micro",
            "Engine": "mysql",
            "DBInstanceStatus": "available",
            "MasterUsername": "admin",
            "DBName": "labdb",
            "Endpoint": {
                "Address": "lab-mysql.cne4ueim8lb3.ap-northeast-1.rds.amazonaws.com",
                "Port": 3306,
                "HostedZoneId": "Z24O6O9L7SGTNB"
            },
            "AllocatedStorage": 20,
            "InstanceCreateTime": "2026-01-20T17:49:15.011000+00:00",
            "PreferredBackupWindow": "15:02-15:32",
            "BackupRetentionPeriod": 0,
            "DBSecurityGroups": [],
            "VpcSecurityGroups": [
                {
                    "VpcSecurityGroupId": "sg-02bb0ebcada51e224",
                    "Status": "active"
                }
            ],
            "DBParameterGroups": [
                {
                    "DBParameterGroupName": "default.mysql8.0",
                    "ParameterApplyStatus": "in-sync"
                }
            ],
            "AvailabilityZone": "ap-northeast-1c",
            "DBSubnetGroup": {
                "DBSubnetGroupName": "armageddon-lab-1a-db-subnet-group",
                "DBSubnetGroupDescription": "Managed by Terraform",
                "VpcId": "vpc-0ea1435ca15091d4f",
                "SubnetGroupStatus": "Complete",
                "Subnets": [
                    {
                        "SubnetIdentifier": "subnet-05726d35c5fdec73d",
                        "SubnetAvailabilityZone": {
                            "Name": "ap-northeast-1a"
                        },
                        "SubnetOutpost": {},
                        "SubnetStatus": "Active"
                    },
                    {
                        "SubnetIdentifier": "subnet-0ab27d311ab48be24",
                        "SubnetAvailabilityZone": {
                            "Name": "ap-northeast-1c"
                        },
                        "SubnetOutpost": {},
                        "SubnetStatus": "Active"
                    }
                ]
            },
            "PreferredMaintenanceWindow": "thu:18:22-thu:18:52",
            "UpgradeRolloutOrder": "second",
            "PendingModifiedValues": {},
            "MultiAZ": true,
            "EngineVersion": "8.0.43",
            "AutoMinorVersionUpgrade": true,
            "ReadReplicaDBInstanceIdentifiers": [],
            "LicenseModel": "general-public-license",
            "StorageThroughput": 0,
            "OptionGroupMemberships": [
                {
                    "OptionGroupName": "default:mysql-8-0",
                    "Status": "in-sync"
                }
            ],
            "SecondaryAvailabilityZone": "ap-northeast-1a",
            "PubliclyAccessible": false,
            "StorageType": "gp2",
            "DbInstancePort": 0,
            "StorageEncrypted": false,
            "DbiResourceId": "db-J2PRCPLKEFOFORRBSF32RB2LEY",
            "CACertificateIdentifier": "rds-ca-rsa2048-g1",
            "DomainMemberships": [],
            "CopyTagsToSnapshot": false,
            "MonitoringInterval": 0,
            "DBInstanceArn": "arn:aws:rds:ap-northeast-1:<ACCOUNT_ID>:db:lab-mysql",
            "IAMDatabaseAuthenticationEnabled": false,
            "DatabaseInsightsMode": "standard",
            "PerformanceInsightsEnabled": false,
            "DeletionProtection": false,
            "AssociatedRoles": [],
            "TagList": [],
            "CustomerOwnedIpEnabled": false,
            "NetworkType": "IPV4",
            "ActivityStreamStatus": "stopped",
            "BackupTarget": "region",
            "CertificateDetails": {
                "CAIdentifier": "rds-ca-rsa2048-g1",
                "ValidTill": "2027-01-20T17:47:49+00:00"
            },
            "DedicatedLogVolume": false,
            "IsStorageConfigUpgradeAvailable": false,
            "EngineLifecycleSupport": "open-source-rds-extended-support"
        }
    ]
}

# Verify RDS security groups explicitly

aws rds describe-db-instances \
  --db-instance-identifier lab-mysql \
  --region ap-northeast-1 \
  --query "DBInstances[].VpcSecurityGroups[].VpcSecurityGroupId" \
  --output table

--------------------------
|   DescribeDBInstances  |
+------------------------+
|  sg-02bb0ebcada51e224  |
+------------------------+

# Verify RDS subnet placement

aws rds describe-db-subnet-groups \
  --region ap-northeast-1 \
  --query "DBSubnetGroups[].{Name:DBSubnetGroupName,Vpc:VpcId,Subnets:Subnets[].SubnetIdentifier}" \
  --output table

  ----------------------------------------------------------------
|                    DescribeDBSubnetGroups                    |
+------------------------------------+-------------------------+
|                Name                |           Vpc           |
+------------------------------------+-------------------------+
|  armageddon-lab-1a-db-subnet-group |  vpc-0ea1435ca15091d4f  |
+------------------------------------+-------------------------+
||                           Subnets                          ||
|+------------------------------------------------------------+|
||  subnet-05726d35c5fdec73d                                  ||
||  subnet-0ab27d311ab48be24                                  ||
|+------------------------------------------------------------+|
|                    DescribeDBSubnetGroups                    |
+----------------------------------+---------------------------+
|               Name               |            Vpc            |
+----------------------------------+---------------------------+
|  default-vpc-0d52718038589c898   |  vpc-0d52718038589c898    |
+----------------------------------+---------------------------+
||                           Subnets                          ||
|+------------------------------------------------------------+|
||  subnet-0ce4ef4aca9147285                                  ||
||  subnet-044e6a7d484a327bb                                  ||
|+------------------------------------------------------------+

# Verify Network Exposure (Fast Sanity Checks) Check if RDS is publicly reachable (quick flag)

aws rds describe-db-instances \
  --db-instance-identifier lab-mysql \
  --region ap-northeast-1 \
  --query "DBInstances[].PubliclyAccessible" \
  --output text

  False

# Verify Secrets Manager (Existence, Metadata, Access)

aws secretsmanager list-secrets \
  --region ap-northeast-1 \
  --query "SecretList[].{Name:Name,ARN:ARN,Rotation:RotationEnabled}" \
  --output table

-----------------------------------------------------------------------------------------------------------------------
|                                                     ListSecrets                                                     |
+------------------------------------------------------------------------------------+-------------------+------------+
|                                         ARN                                        |       Name        | Rotation   |
+------------------------------------------------------------------------------------+-------------------+------------+
|  arn:aws:secretsmanager:ap-northeast-1:<ACCOUNT_ID>:secret:lab-1a/rds/mysql-XtS30E |  lab-1a/rds/mysql |  None      |
+------------------------------------------------------------------------------------+-------------------+------------+

# Describe a specific secret (NO value exposure)

aws secretsmanager describe-secret \
  --secret-id lab-1a/rds/mysql \
  --region ap-northeast-1 \
  --output json

{
    "ARN": "arn:aws:secretsmanager:ap-northeast-1:<ACCOUNT_ID>:secret:lab-1a/rds/mysql-XtS30E",
    "Name": "lab-1a/rds/mysql",
    "LastChangedDate": "2026-01-17T18:38:32.107000+00:00",
    "LastAccessedDate": "2026-01-20T00:00:00+00:00",
    "VersionIdsToStages": {
        "2945220d-0d6d-40dc-96a4-cfdde1dae69a": [
            "AWSPREVIOUS"
        ],
        "2ce74002-655c-4385-8634-b563c5fd9c1a": [
            "AWSCURRENT"
        ]
    },
    "CreatedDate": "2026-01-16T18:00:29.238000+00:00"
}

# Verify which IAM principals can access the secret


aws secretsmanager get-resource-policy \
  --secret-id  lab-1a/rds/mysql \
  --region ap-northeast-1 \
  --output json

{
    "ARN": "arn:aws:secretsmanager:ap-northeast-1:<ACCOUNT_ID>:secret:lab-1a/rds/mysql-XtS30E",
    "Name": "lab-1a/rds/mysql"
}

# Verify IAM Role Attached to an EC2 Instance Step 1: Identify the EC2 instance

aws ec2 describe-instances \
  --filters Name=tag:Name,Values=MyInstance \
  --region ap-northeast-1 \
  --query "Reservations[].Instances[].InstanceId" \
  --output text

i-01bb8e2d1d16a0455 

# Step 2: Check the IAM role attached to the instance

aws ec2 describe-instances \
  --instance-ids i-01bb8e2d1d16a0455  \
  --region ap-northeast-1 \
  --query "Reservations[].Instances[].IamInstanceProfile.Arn" \
  --output text

  arn:aws:iam::<ACCOUNT_ID>:instance-profile/armageddon-lab-1a-ec2-secrets-profile

# Step 3: Resolve instance profile → role name

aws iam get-instance-profile \
  --instance-profile-name armageddon-lab-1a-ec2-secrets-profile \
  --query "InstanceProfile.Roles[].RoleName" \
  --output text

armageddon-lab-1a-ec2-secrets-role

# Verify IAM Role Permissions (Critical) List policies attached to the role

aws iam list-attached-role-policies \
  --role-name armageddon-lab-1a-ec2-secrets-role \
  --output table

-----------------------------------------------------------------------------------------------------------------
|                                           ListAttachedRolePolicies                                            |
+---------------------------------------------------------------------------------------------------------------+
||                                              AttachedPolicies                                               ||
|+----------------------------------------------------------------------+--------------------------------------+|
||                               PolicyArn                              |             PolicyName               ||
|+----------------------------------------------------------------------+--------------------------------------+|
||  arn:aws:iam::<ACCOUNT_ID>:policy/armageddon-lab-1a-EC2ReadRDSSecret |  armageddon-lab-1a-EC2ReadRDSSecret  ||
|+----------------------------------------------------------------------+--------------------------------------+|

# List inline policies (often forgotten)
aws iam list-role-policies \
  --role-name armageddon-lab-1a-ec2-secrets-role \
  --output table

------------------
|ListRolePolicies|
+----------------+
||  PolicyNames ||
|+--------------+|
||  ec2_policy  ||
|+--------------+|

# Inspect a specific managed policy
aws iam get-policy-version \
  --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/armageddon-lab-1a-EC2ReadRDSSecret \
  --version-id v1 \
  --output json

  {
    "PolicyVersion": {
        "Document": {
            "Statement": [
                {
                    "Action": [
                        "secretsmanager:GetSecretValue",
                        "secretsmanager:DescribeSecret"
                    ],
                    "Effect": "Allow",
                    "Resource": "arn:aws:secretsmanager:ap-northeast-1:<ACCOUNT_ID>:secret:lab-1a/rds/mysql*",
                    "Sid": "ReadSpecificSecret"
                },
                {
                    "Action": "kms:Decrypt",
                    "Effect": "Allow",
                    "Resource": "arn:aws:kms:<REGION>:<ACCOUNT_ID>:key/<KMS_KEY_ID>",
                    "Sid": "AllowKMSDecrypt"
                }
            ],
            "Version": "2012-10-17"
        },
        "VersionId": "v1",
        "IsDefaultVersion": true,
        "CreateDate": "2026-01-20T17:45:16+00:00"
    }
}

# Verify EC2 → RDS access path (security-group–to–security-group)

aws ec2 describe-security-groups \
  --group-ids sg-067b8ecdc3b5fbc26 \
  --region ap-northeast-1 \
  --query "SecurityGroups[].IpPermissions"

  [
    [
        {
            "IpProtocol": "tcp",
            "FromPort": 80,
            "ToPort": 80,
            "UserIdGroupPairs": [],
            "IpRanges": [
                {
                    "Description": "Allow HTTP traffic",
                    "CidrIp": "0.0.0.0/0"
                }
            ],
            "Ipv6Ranges": [],
            "PrefixListIds": []
        },
        {
            "IpProtocol": "tcp",
            "FromPort": 22,
            "ToPort": 22,
            "UserIdGroupPairs": [],
            "IpRanges": [
                {
                    "CidrIp": "0.0.0.0/0"
                }
            ],
            "Ipv6Ranges": [],
            "PrefixListIds": []
        }
    ]
]

# Verify That EC2 Can Actually Read the Secret (From the Instance) From inside the EC2 instance:

{
    "UserId": "AROATZY6AEXHNFHWN3V4U:i-01bb8e2d1d16a0455",
    "Account": "<ACCOUNT_ID>",
    "Arn": "arn:aws:sts::<ACCOUNT_ID>:assumed-role/armageddon-lab-1a-ec2-secrets-role/i-01bb8e2d1d16a0455"
}

# Then test access:
aws secretsmanager describe-secret \
  --secret-id lab-1a/rds/mysql \
  --region ap-northeast-1

  {
    "ARN": "arn:aws:secretsmanager:ap-northeast-1:<ACCOUNT_ID>:secret:lab-1a/rds/mysql-XtS30E",
    "Name": "lab-1a/rds/mysql",
    "LastChangedDate": "2026-01-17T18:38:32.107000+00:00",
    "LastAccessedDate": "2026-01-20T00:00:00+00:00",
    "VersionIdsToStages": {
        "2945220d-0d6d-40dc-96a4-cfdde1dae69a": [
            "AWSPREVIOUS"
        ],
        "2ce74002-655c-4385-8634-b563c5fd9c1a": [
            "AWSCURRENT"
        ]
    },
    "CreatedDate": "2026-01-16T18:00:29.238000+00:00"
}

