# Bonus A CLI Verification — EC2 Notes App → RDS MySQL

- Generated (UTC): `2026-02-03T17:48:49Z`
- Region: `ap-northeast-1`
- Secret name: `lab-1c/rds/mysql`
- EC2 Name tag lookup: `lab-ec2-app`
- RDS identifier: `lab-mysql`

## Resolved IDs (best effort)

- EC2 InstanceId: `i-0498836f145c8268a`
- EC2 SG: `NOT_FOUND`
- RDS SG: `NOT_FOUND`
- RDS Endpoint (TF output): `NOT_FOUND`

## Part 1 — Security Groups (inventory + inspection)


### List all security groups (region inventory)

```bash
aws ec2 describe-security-groups --region ap-northeast-1 --query SecurityGroups[].{GroupId:GroupId,Name:GroupName,VpcId:VpcId} --output table
```

```text
--------------------------------------------------------------------------------
|                            DescribeSecurityGroups                            |
+----------------------+-----------------------------+-------------------------+
|        GroupId       |            Name             |          VpcId          |
+----------------------+-----------------------------+-------------------------+
|  sg-0885de7e0e49f3735|  rds-lab-1c                 |  vpc-02425b166ba6440a0  |
|  sg-03bdd0afcf95a38c6|  default                    |  vpc-02425b166ba6440a0  |
|  sg-0ecff9436f56953b5|  ec2-armageddon-lab-1c      |  vpc-02425b166ba6440a0  |
|  sg-08ff1530754d496bf|  armageddon-lab-1c-vpce-sg  |  vpc-02425b166ba6440a0  |
|  sg-0d0d7d0265d2f695a|  lambda-rotation-lab-1c     |  vpc-02425b166ba6440a0  |
|  sg-03c102f59d7e0b79b|  default                    |  vpc-0ad0fb7075d9225d0  |
+----------------------+-----------------------------+-------------------------+
```

## Part 1 — Verify which resources use a given SG

## Part 1 — RDS instance checks (public flag, SGs, subnet group)


### List all RDS instances (inventory)

```bash
aws rds describe-db-instances --region ap-northeast-1 --query DBInstances[].{DB:DBInstanceIdentifier,Engine:Engine,Public:PubliclyAccessible,Vpc:DBSubnetGroup.VpcId} --output table
```

```text
------------------------------------------------------------
|                    DescribeDBInstances                   |
+-----------+---------+---------+--------------------------+
|    DB     | Engine  | Public  |           Vpc            |
+-----------+---------+---------+--------------------------+
|  lab-mysql|  mysql  |  False  |  vpc-02425b166ba6440a0   |
+-----------+---------+---------+--------------------------+
```


### Inspect specific RDS instance (json) — lab-mysql

```bash
aws rds describe-db-instances --db-instance-identifier lab-mysql --region ap-northeast-1 --output json
```

```text
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
            "InstanceCreateTime": "2026-02-03T17:39:11.440000+00:00",
            "PreferredBackupWindow": "18:19-18:49",
            "BackupRetentionPeriod": 0,
            "DBSecurityGroups": [],
            "VpcSecurityGroups": [
                {
                    "VpcSecurityGroupId": "sg-0885de7e0e49f3735",
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
                "DBSubnetGroupName": "armageddon-lab-1c-db-subnet-group",
                "DBSubnetGroupDescription": "Managed by Terraform",
                "VpcId": "vpc-02425b166ba6440a0",
                "SubnetGroupStatus": "Complete",
                "Subnets": [
                    {
                        "SubnetIdentifier": "subnet-04360cb42b1bc5d02",
                        "SubnetAvailabilityZone": {
                            "Name": "ap-northeast-1a"
                        },
                        "SubnetOutpost": {},
                        "SubnetStatus": "Active"
                    },
                    {
                        "SubnetIdentifier": "subnet-00ff19c2b18a58701",
                        "SubnetAvailabilityZone": {
                            "Name": "ap-northeast-1c"
                        },
                        "SubnetOutpost": {},
                        "SubnetStatus": "Active"
                    }
                ]
            },
            "PreferredMaintenanceWindow": "wed:19:13-wed:19:43",
            "UpgradeRolloutOrder": "second",
            "PendingModifiedValues": {},
            "MultiAZ": false,
            "EngineVersion": "8.0.44",
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
            "PubliclyAccessible": false,
            "StorageType": "gp2",
            "DbInstancePort": 0,
            "StorageEncrypted": false,
            "DbiResourceId": "db-XGYGSBRQGKLNE5QLPNII7UMDWA",
            "CACertificateIdentifier": "rds-ca-rsa2048-g1",
            "DomainMemberships": [],
            "CopyTagsToSnapshot": false,
            "MonitoringInterval": 0,
            "DBInstanceArn": "arn:aws:rds:ap-northeast-1:261519058382:db:lab-mysql",
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
                "ValidTill": "2027-02-03T17:37:41+00:00"
            },
            "DedicatedLogVolume": false,
            "IsStorageConfigUpgradeAvailable": false,
            "EngineLifecycleSupport": "open-source-rds-extended-support"
        }
    ]
}
```


### RDS SG IDs (table) — lab-mysql

```bash
aws rds describe-db-instances --db-instance-identifier lab-mysql --region ap-northeast-1 --query DBInstances[].VpcSecurityGroups[].VpcSecurityGroupId --output table
```

```text
--------------------------
|   DescribeDBInstances  |
+------------------------+
|  sg-0885de7e0e49f3735  |
+------------------------+
```


### RDS subnet groups (placement)

```bash
aws rds describe-db-subnet-groups --region ap-northeast-1 --query DBSubnetGroups[].{Name:DBSubnetGroupName,Vpc:VpcId,Subnets:Subnets[].SubnetIdentifier} --output table
```

```text
----------------------------------------------------------------
|                    DescribeDBSubnetGroups                    |
+------------------------------------+-------------------------+
|                Name                |           Vpc           |
+------------------------------------+-------------------------+
|  armageddon-lab-1c-db-subnet-group |  vpc-02425b166ba6440a0  |
+------------------------------------+-------------------------+
||                           Subnets                          ||
|+------------------------------------------------------------+|
||  subnet-04360cb42b1bc5d02                                  ||
||  subnet-00ff19c2b18a58701                                  ||
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
|+------------------------------------------------------------+|
```


### RDS PubliclyAccessible quick flag (expected: false)

```bash
aws rds describe-db-instances --db-instance-identifier lab-mysql --region ap-northeast-1 --query DBInstances[].PubliclyAccessible --output text
```

```text
False
```

## Part 3 — Secrets Manager checks (metadata only)


### List secrets (name/arn/rotation)

```bash
aws secretsmanager list-secrets --region ap-northeast-1 --query SecretList[].{Name:Name,ARN:ARN,Rotation:RotationEnabled} --output table
```

```text
-----------------------------------------------------------------------------------------------------------------------
|                                                     ListSecrets                                                     |
+------------------------------------------------------------------------------------+-------------------+------------+
|                                         ARN                                        |       Name        | Rotation   |
+------------------------------------------------------------------------------------+-------------------+------------+
|  arn:aws:secretsmanager:ap-northeast-1:261519058382:secret:lab-1a/rds/mysql-XtS30E |  lab-1a/rds/mysql |  None      |
|  arn:aws:secretsmanager:ap-northeast-1:261519058382:secret:lab-1b/rds/mysql-IgxXx6 |  lab-1b/rds/mysql |  False     |
|  arn:aws:secretsmanager:ap-northeast-1:261519058382:secret:lab-1c/rds/mysql-JXTWyu |  lab-1c/rds/mysql |  True      |
|  arn:aws:secretsmanager:ap-northeast-1:261519058382:secret:lab/rds/mysql-WFTljm    |  lab/rds/mysql    |  None      |
+------------------------------------------------------------------------------------+-------------------+------------+
```


### Describe secret (NO value exposure) — lab-1c/rds/mysql

```bash
aws secretsmanager describe-secret --secret-id lab-1c/rds/mysql --region ap-northeast-1 --output json
```

```text
{
    "ARN": "arn:aws:secretsmanager:ap-northeast-1:261519058382:secret:lab-1c/rds/mysql-JXTWyu",
    "Name": "lab-1c/rds/mysql",
    "RotationEnabled": true,
    "RotationLambdaARN": "arn:aws:lambda:ap-northeast-1:261519058382:function:lab-1c-rds-rotation-mysql",
    "RotationRules": {
        "AutomaticallyAfterDays": 30
    },
    "LastRotatedDate": "2026-02-02T18:16:24.409000+01:00",
    "LastChangedDate": "2026-02-03T18:42:24.335000+01:00",
    "LastAccessedDate": "2026-02-03T01:00:00+01:00",
    "NextRotationDate": "2026-03-06T00:59:59+01:00",
    "Tags": [],
    "VersionIdsToStages": {
        "terraform-20260202192845100500000001": [
            "AWSPREVIOUS"
        ],
        "terraform-20260203173402627700000001": [
            "AWSCURRENT"
        ],
        "terraform-20260203174223578300000001": [
            "AWSPENDING"
        ]
    },
    "CreatedDate": "2026-02-01T17:35:48.499000+01:00"
}
```

## Part 3 — IAM role attached to EC2 + policy checks


### EC2 instance IAM instance profile ARN (empty = finding) — i-0498836f145c8268a

```bash
aws ec2 describe-instances --instance-ids i-0498836f145c8268a --region ap-northeast-1 --query Reservations[].Instances[].IamInstanceProfile.Arn --output text
```

```text
arn:aws:iam::261519058382:instance-profile/armageddon-lab-1c-ec2-secrets-profile
```


### Resolve instance profile → role name — armageddon-lab-1c-ec2-secrets-profile

```bash
aws iam get-instance-profile --instance-profile-name armageddon-lab-1c-ec2-secrets-profile --query InstanceProfile.Roles[].RoleName --output text
```

```text
armageddon-lab-1c-ec2-secrets-role
```


### List attached managed policies — armageddon-lab-1c-ec2-secrets-role

```bash
aws iam list-attached-role-policies --role-name armageddon-lab-1c-ec2-secrets-role --output table
```

```text
-----------------------------------------------------------------------------------------------------------------------------
|                                                 ListAttachedRolePolicies                                                  |
+---------------------------------------------------------------------------------------------------------------------------+
||                                                    AttachedPolicies                                                     ||
|+----------------------------------------------------------------------------+--------------------------------------------+|
||                                  PolicyArn                                 |                PolicyName                  ||
|+----------------------------------------------------------------------------+--------------------------------------------+|
||  arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore                      |  AmazonSSMManagedInstanceCore              ||
||  arn:aws:iam::aws:policy/CloudWatchLogsFullAccess                          |  CloudWatchLogsFullAccess                  ||
||  arn:aws:iam::261519058382:policy/armageddon-lab-1c-EC2ReadRDSSecret       |  armageddon-lab-1c-EC2ReadRDSSecret        ||
||  arn:aws:iam::261519058382:policy/armageddon-lab-1c-ssm-read-policy        |  armageddon-lab-1c-ssm-read-policy         ||
||  arn:aws:iam::261519058382:policy/armageddon-lab-1c-cloudwatch-logs-policy |  armageddon-lab-1c-cloudwatch-logs-policy  ||
|+----------------------------------------------------------------------------+--------------------------------------------+|
```


### List inline policies — armageddon-lab-1c-ec2-secrets-role

```bash
aws iam list-role-policies --role-name armageddon-lab-1c-ec2-secrets-role --output table
```

```text
------------------
|ListRolePolicies|
+----------------+
||  PolicyNames ||
|+--------------+|
||  ec2_policy  ||
|+--------------+|
```

## Part 5 — App smoke test (optional)

> If EC2 has a public IP/DNS and the app is bound to port 80, these endpoints should work:
> - /init
> - /add?note=first_note
> - /list

> This script does not curl by default to avoid false negatives if inbound 80 is intentionally restricted.

## Recommended Evidence Exports (audit-friendly)

> If you need raw json artifacts, run these and attach outputs to deliverables:

```bash
# Example SG export (update SG id):
aws ec2 describe-security-groups --group-ids <sg-id> --region ap-northeast-1 > sg.json

# Example RDS export:
aws rds describe-db-instances --db-instance-identifier lab-mysql --region ap-northeast-1 > rds.json

# Example Secret export (metadata only):
aws secretsmanager describe-secret --secret-id lab-1c/rds/mysql --region ap-northeast-1 > secret.json

# Example EC2 export:
aws ec2 describe-instances --instance-ids i-0498836f145c8268a --region ap-northeast-1 > instance.json

# Example role policies:
aws iam list-attached-role-policies --role-name <role-name> > role-policies.json
aws iam list-role-policies --role-name <role-name> > role-inline-policies.json
```

---
✅ Script completed at `2026-02-03T17:49:06Z`
