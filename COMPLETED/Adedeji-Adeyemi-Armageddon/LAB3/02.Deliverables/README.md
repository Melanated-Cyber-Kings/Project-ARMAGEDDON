# LAB3 --- Japan Medical Global Architecture & Compliance Validation

APPI-Aligned Multi-Region Design with Transit Gateway & Audit Evidence

## Overview

LAB3 teaches how to design and prove compliance for a regulated,
multi-region medical workload where legal requirements drive
architecture.

This lab is split conceptually into two parts:

-   Lab 3A --- Architecture & Regional Design
-   Lab 3B --- Audit Evidence & Compliance Verification

Together they demonstrate how engineers:

-   Design asymmetric global systems
-   Enforce data-residency laws
-   Create controlled cross-region data corridors
-   Produce audit-ready proof
-   Communicate compliance posture to regulators and auditors

------------------------------------------------------------------------

## Architectural Scenario

Japan's privacy law --- APPI (個人情報保護法) --- requires that medical
PHI belonging to Japanese citizens be stored physically inside Japan.

This applies even when:

-   A patient is traveling
-   A doctor is overseas
-   The application is globally accessible

Access is allowed. Storage is not.

------------------------------------------------------------------------

## Regional Roles

### Tokyo --- Primary Region (Authoritative Data)

Tokyo is the source of truth and contains:

-   RDS medical database
-   Primary VPC
-   Application tier
-   Transit Gateway hub
-   Parameter Store & Secrets Manager
-   Logging, auditing, and backups

All PHI at rest lives here.

If Tokyo becomes unavailable, the system may degrade --- but data
residency is never violated.

------------------------------------------------------------------------

### São Paulo --- Secondary Region (Stateless Compute)

São Paulo reduces latency for South American users and contains:

-   VPC
-   EC2 + Auto Scaling Group
-   Application tier
-   Transit Gateway spoke

It does not contain:

-   RDS
-   Read replicas
-   Backups
-   Any persistent PHI storage

São Paulo is stateless compute. All reads and writes go directly to
Tokyo.

------------------------------------------------------------------------

## Key Architectural Truths

### Compliance

-   PHI storage stays in Tokyo
-   Compute can move
-   Access can be global
-   Storage cannot

### Engineering

-   Transit Gateway creates a controlled corridor
-   CloudFront provides a single global URL
-   São Paulo is stateless
-   Tokyo is authoritative

------------------------------------------------------------------------

## Transit Gateway Design Pattern

Transit Gateway is regional.

Correct regulated-enterprise pattern:

-   TGW in Tokyo
-   TGW in São Paulo
-   TGW Peering Attachment
-   Each VPC attaches to its local TGW
-   Routes propagate across the peering

------------------------------------------------------------------------

## End-to-End Traffic Flow

Doctor in São Paulo\
CloudFront\
São Paulo EC2\
TGW (São Paulo)\
TGW Peering\
TGW (Tokyo)\
Tokyo VPC\
Tokyo RDS

All traffic remains on the AWS backbone and is encrypted.

------------------------------------------------------------------------

## Single Global Entry Point


CloudFront:

-   Terminates TLS
-   Applies WAF
-   Routes users to the nearest healthy region
-   Never stores PHI
-   Caches only explicitly safe content

------------------------------------------------------------------------

## Terraform & DevOps Structure

### Multi-State Reality

Each region is deployed from a separate Terraform state:

-   Tokyo state
-   São Paulo state

They communicate only through:

-   Remote state references
-   Outputs
-   Explicit variables

------------------------------------------------------------------------

### Expected Repository Layout

    lab-3/
    ├── tokyo/
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    │
    ├── saopaulo/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── data.tf

------------------------------------------------------------------------

## Security Model

-   RDS inbound only from:
    -   Tokyo application subnets
    -   São Paulo VPC CIDR
-   No public DB access
-   No PHI stored outside Tokyo
-   All access logged

This is compliance by design, not policy.

------------------------------------------------------------------------

# LAB3 Audit Evidence Pack

LAB3 requires producing CLI-verifiable proof that the architecture
behaves correctly.

------------------------------------------------------------------------

## Deliverable A --- Audit Pack

    audit-pack/
    ├── 00_architecture-summary.md
    ├── 01_data-residency-proof.txt
    ├── 02_edge-proof-cloudfront.txt
    ├── 03_waf-proof.txt
    ├── 04_cloudtrail-change-proof.txt
    ├── 05_network-corridor-proof.txt
    └── evidence.json

------------------------------------------------------------------------

## Verification Requirements

### Data Residency --- RDS Only in Tokyo

Tokyo:

``` bash
aws rds describe-db-instances `
  --region ap-northeast-1 `
  --query "DBInstances[].{DB:DBInstanceIdentifier,AZ:AvailabilityZone,Region:'ap-northeast-1',Endpoint:Endpoint.Address}"
```

#### OUTPUT
[
    {
        "DB": "terraform-20260307121935033300000002",
        "AZ": "ap-northeast-1c",
        "Region": "ap-northeast-1",
        "Endpoint": "terraform-20260307121935033300000002.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com"
    }
]



São Paulo:

``` bash
aws rds describe-db-instances 
  --region sa-east-1 
  --query "DBInstances[].DBInstanceIdentifier"
```
#### OUTPUT
[]

 aws rds describe-db-instances --region sa-east-1
{
    "DBInstances": []
}


------------------------------------------------------------------------



### CloudFront Edge Proof

``` bash
curl -I https://tritechsite.click/api/public-feed
```

Logs:

``` bash
aws s3 ls s3://medical-vault-audit-logs-sprint3-v1-200819971986/AWSLogs/ --recursive
```

2026-03-07 13:41:21          0 AWSLogs/420228061920/CloudTrail-Digest/
2026-03-07 14:07:50        367 AWSLogs/420228061920/CloudTrail-Digest/ap-northeast-1/2026/03/07/420228061920_CloudTrail-Digest_ap-northeast-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 14:07:37        372 AWSLogs/420228061920/CloudTrail-Digest/ap-northeast-2/2026/03/07/420228061920_CloudTrail-Digest_ap-northeast-2_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 14:08:03        366 AWSLogs/420228061920/CloudTrail-Digest/ap-northeast-3/2026/03/07/420228061920_CloudTrail-Digest_ap-northeast-3_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 14:07:20        372 AWSLogs/420228061920/CloudTrail-Digest/ap-south-1/2026/03/07/420228061920_CloudTrail-Digest_ap-south-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 14:08:04        371 AWSLogs/420228061920/CloudTrail-Digest/ap-southeast-1/2026/03/07/420228061920_CloudTrail-Digest_ap-southeast-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 14:08:20        374 AWSLogs/420228061920/CloudTrail-Digest/ap-southeast-2/2026/03/07/420228061920_CloudTrail-Digest_ap-southeast-2_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 14:07:37        377 AWSLogs/420228061920/CloudTrail-Digest/ca-central-1/2026/03/07/420228061920_CloudTrail-Digest_ca-central-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 14:08:32        377 AWSLogs/420228061920/CloudTrail-Digest/eu-central-1/2026/03/07/420228061920_CloudTrail-Digest_eu-central-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 14:08:20        375 AWSLogs/420228061920/CloudTrail-Digest/eu-north-1/2026/03/07/420228061920_CloudTrail-Digest_eu-north-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 14:07:47        373 AWSLogs/420228061920/CloudTrail-Digest/eu-west-1/2026/03/07/420228061920_CloudTrail-Digest_eu-west-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 14:07:40        375 AWSLogs/420228061920/CloudTrail-Digest/eu-west-2/2026/03/07/420228061920_CloudTrail-Digest_eu-west-2_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 14:08:05        374 AWSLogs/420228061920/CloudTrail-Digest/eu-west-3/2026/03/07/420228061920_CloudTrail-Digest_eu-west-3_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 14:08:08        373 AWSLogs/420228061920/CloudTrail-Digest/sa-east-1/2026/03/07/420228061920_CloudTrail-Digest_sa-east-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 14:07:21        372 AWSLogs/420228061920/CloudTrail-Digest/us-east-1/2026/03/07/420228061920_CloudTrail-Digest_us-east-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 14:08:09        370 AWSLogs/420228061920/CloudTrail-Digest/us-east-2/2026/03/07/420228061920_CloudTrail-Digest_us-east-2_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 14:07:28        371 AWSLogs/420228061920/CloudTrail-Digest/us-west-1/2026/03/07/420228061920_CloudTrail-Digest_us-west-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 14:07:46        372 AWSLogs/420228061920/CloudTrail-Digest/us-west-2/2026/03/07/420228061920_CloudTrail-Digest_us-west-2_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 13:41:21          0 AWSLogs/420228061920/CloudTrail/
2026-03-07 13:46:31       7103 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1350Z_Rfqu67OqV4yoGi1D.json.gz
2026-03-07 13:51:22      12086 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1355Z_ScARf8ingRDaudUy.json.gz
2026-03-07 13:56:23      13965 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1400Z_AmsalGiYC4kErIwo.json.gz
2026-03-07 14:01:24      10551 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1405Z_3rzopinxQKL71kmH.json.gz
2026-03-07 14:05:57       1226 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1405Z_l1kgicBLt00WfnYj.json.gz
2026-03-07 14:07:34      10314 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1410Z_IN5BAvlL9NQJzyNo.json.gz
2026-03-07 14:12:24      14877 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1415Z_BDR3c3okImqkaxxx.json.gz
2026-03-07 14:17:14      13644 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1420Z_lLdqFsYAlULBvU9L.json.gz
2026-03-07 14:22:05       5036 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1425Z_i0pmSqm0NmimV10t.json.gz
2026-03-07 14:23:59       1075 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1425Z_isHuwPlYRlOvTSpH.json.gz
2026-03-07 14:27:05      10446 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1430Z_aFG96OYgZ9C0iFAx.json.gz
2026-03-07 14:32:06      12791 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1435Z_3yE20FAvGQL8ofIQ.json.gz
2026-03-07 14:36:57      10598 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1440Z_GriU9iTbFyp8mWll.json.gz
2026-03-07 14:41:46      13538 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1445Z_en3RgM39pbqznBfI.json.gz
2026-03-07 14:47:27      21850 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1450Z_bzl7mRIjzWYvyfOH.json.gz
2026-03-07 13:49:08       1952 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1350Z_bCoHXy0xFYwgo9A8.json.gz
2026-03-07 13:53:58       2759 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1355Z_UKmJ9HhZDaKJNVPp.json.gz
2026-03-07 13:58:59       1855 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1400Z_IPDiDDGC22NyxSuo.json.gz
2026-03-07 14:03:59       1715 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1405Z_2typIHsXBFBi43IZ.json.gz
2026-03-07 14:09:00       2045 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1410Z_Wg30BQnK92ARjnFq.json.gz
2026-03-07 14:14:01       2919 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1415Z_4u8FzjeVOiimzmUs.json.gz
2026-03-07 14:19:01       1852 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1420Z_LnZO90cn2srIPJ3y.json.gz
2026-03-07 14:24:03       2760 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1425Z_BjBgKLjWkrgy32HS.json.gz
2026-03-07 14:29:04       4664 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1430Z_9lUHKcuj3CukNmdl.json.gz
2026-03-07 14:34:05       2122 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1435Z_vnL04lfx4ExASrDn.json.gz
2026-03-07 14:38:55       4724 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1440Z_zP5lznQBdA8BlPo2.json.gz
2026-03-07 14:44:06       1724 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1445Z_3xDEII4B68KNkLdR.json.gz
2026-03-07 13:44:33        625 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1345Z_2GYySUSG2XhKnNcN.json.gz
2026-03-07 13:47:56        590 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1345Z_fSAAevWpyLyXPyDV.json.gz
2026-03-07 13:49:44       5448 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1350Z_bWZroXgjMdms29zq.json.gz
2026-03-07 13:53:16       2122 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1355Z_vYcECyUE5zY6m0ss.json.gz
2026-03-07 13:57:55       2399 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1400Z_BNNTVF084PWgx2NP.json.gz
2026-03-07 14:03:17       2299 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1400Z_EdpTJSK40U0iLTaC.json.gz
2026-03-07 14:03:16       3745 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1405Z_9pNam3Nz3ZszB7E3.json.gz
2026-03-07 14:13:18        784 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1410Z_Fhp0IFd1hRUTBVkp.json.gz
2026-03-07 14:09:56       6276 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1410Z_vzdtfJkSOoDduMYj.json.gz
2026-03-07 14:15:38       1940 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1420Z_Vt1FEQFYP9MVfzi7.json.gz
2026-03-07 14:20:38       5517 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1420Z_X6fbhelmzb9LSawG.json.gz
2026-03-07 14:21:49        668 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1425Z_3t6mtS6hC1xWjsaz.json.gz
2026-03-07 14:33:10        621 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1430Z_6rx2lFKVO9w0o6qI.json.gz
2026-03-07 14:33:20       1460 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1430Z_C4sxsYwYx5hevTtF.json.gz
2026-03-07 14:27:59       2400 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1430Z_eYh2L68kPp1VoBbK.json.gz
2026-03-07 14:33:11       4396 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1435Z_JiGzwqE9XM3XQAPb.json.gz
2026-03-07 14:40:22       2628 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1440Z_6NDwAZS2JLhaHmqt.json.gz
2026-03-07 14:39:41       5817 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1440Z_Z86tJFZVJ4DRseFE.json.gz
2026-03-07 14:44:32        865 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1445Z_1VR5Y1c6la2PA8rP.json.gz
2026-03-07 14:31:10       1662 AWSLogs/420228061920/CloudTrail/us-west-2/2026/03/07/420228061920_CloudTrail_us-west-2_20260307T1430Z_5bfmNN60jreWMiPI.json.gz
------------------------------------------------------------------------

### WAF Proof
aws logs describe-log-groups --query "logGroups[*].logGroupName" --region us-east-1 --output table
--------------------------------
|       DescribeLogGroups      |
+------------------------------+
|  aws-waf-logs-medical-vault  |
+------------------------------+
``` bash
aws logs tail aws-waf-logs-medical-vault --since 1h --region us-east-1


```

------------------------------------------------------------------------

### CloudTrail Change History

``` bash
aws cloudtrail lookup-events --max-results 5
```
aws cloudtrail lookup-events --max-results 5
{
    "Events": [
        {
            "EventId": "cfece4ca-b016-4184-902e-b5b797085789",
            "EventName": "DescribeLaunchTemplateVersions",
            "ReadOnly": "true",
            "AccessKeyId": "ASIAWDV4LLLQLY2NV2CU",
            "EventTime": "2026-03-07T15:19:46+00:00",
            "EventSource": "ec2.amazonaws.com",
            "Username": "AutoScaling",
            "Resources": [
                {
                    "ResourceType": "AWS::EC2::LaunchTemplate",
                    "ResourceName": "lt-0f20d9a64c382e6b6"
                }
            ],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROAWDV4LLLQC2WCMMTUR:AutoScaling\",\"arn\":\"arn:aws:sts::420228061920:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling\",\"accountId\":\"420228061920\",\"accessKeyId\":\"ASIAWDV4LLLQLY2NV2CU\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROAWDV4LLLQC2WCMMTUR\",\"arn\":\"arn:aws:iam::420228061920:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\",\"accountId\":\"420228061920\",\"userName\":\"AWSServiceRoleForAutoScaling\"},\"attributes\":{\"creationDate\":\"2026-03-07T15:12:33Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"autoscaling.amazonaws.com\"},\"eventTime\":\"2026-03-07T15:19:46Z\",\"eventSource\":\"ec2.amazonaws.com\",\"eventName\":\"DescribeLaunchTemplateVersions\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"autoscaling.amazonaws.com\",\"userAgent\":\"autoscaling.amazonaws.com\",\"requestParameters\":{\"DescribeLaunchTemplateVersionsRequest\":{\"LaunchTemplateVersion\":{\"tag\":1,\"content\":\"$Latest\"},\"LaunchTemplateId\":\"lt-0f20d9a64c382e6b6\"}},\"responseElements\":null,\"requestID\":\"58d75f11-d518-4196-8989-2d54c35608a2\",\"eventID\":\"cfece4ca-b016-4184-902e-b5b797085789\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"420228061920\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "8db5e1a4-3fd2-4332-b78a-5d2671ed2e38",
            "EventName": "ListZonalShifts",
            "ReadOnly": "true",
            "AccessKeyId": "ASIAWDV4LLLQB7AJJQJQ",
            "EventTime": "2026-03-07T15:19:45+00:00",
            "EventSource": "arc-zonal-shift.amazonaws.com",
            "Username": "root",
            "Resources": [],
            "CloudTrailEvent": "{\"eventVersion\":\"1.09\",\"userIdentity\":{\"type\":\"Root\",\"principalId\":\"420228061920\",\"arn\":\"arn:aws:iam::420228061920:root\",\"accountId\":\"420228061920\",\"accessKeyId\":\"ASIAWDV4LLLQB7AJJQJQ\",\"sessionContext\":{\"attributes\":{\"creationDate\":\"2026-03-07T11:51:48Z\",\"mfaAuthenticated\":\"true\"}}},\"eventTime\":\"2026-03-07T15:19:45Z\",\"eventSource\":\"arc-zonal-shift.amazonaws.com\",\"eventName\":\"ListZonalShifts\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"154.47.30.106\",\"userAgent\":\"Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0\",\"requestParameters\":null,\"responseElements\":null,\"requestID\":\"49d9967b-1f9c-484d-bbc1-e8883aaa91a8\",\"eventID\":\"8db5e1a4-3fd2-4332-b78a-5d2671ed2e38\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"420228061920\",\"eventCategory\":\"Management\",\"tlsDetails\":{\"clientProvidedHostHeader\":\"arc-zonal-shift.ap-northeast-1.amazonaws.com\"},\"sessionCredentialFromConsole\":\"true\"}"
        },
        {
            "EventId": "252172ff-2238-4086-ae79-aa6ad366ad20",
            "EventName": "DescribeLaunchTemplateVersions",
            "ReadOnly": "true",
            "AccessKeyId": "ASIAWDV4LLLQLY2NV2CU",
            "EventTime": "2026-03-07T15:19:35+00:00",
            "EventSource": "ec2.amazonaws.com",
            "Username": "AutoScaling",
            "Resources": [
                {
                    "ResourceType": "AWS::EC2::LaunchTemplate",
                    "ResourceName": "lt-0f20d9a64c382e6b6"
                }
            ],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROAWDV4LLLQC2WCMMTUR:AutoScaling\",\"arn\":\"arn:aws:sts::420228061920:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling\",\"accountId\":\"420228061920\",\"accessKeyId\":\"ASIAWDV4LLLQLY2NV2CU\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROAWDV4LLLQC2WCMMTUR\",\"arn\":\"arn:aws:iam::420228061920:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\",\"accountId\":\"420228061920\",\"userName\":\"AWSServiceRoleForAutoScaling\"},\"attributes\":{\"creationDate\":\"2026-03-07T15:12:33Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"autoscaling.amazonaws.com\"},\"eventTime\":\"2026-03-07T15:19:35Z\",\"eventSource\":\"ec2.amazonaws.com\",\"eventName\":\"DescribeLaunchTemplateVersions\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"autoscaling.amazonaws.com\",\"userAgent\":\"autoscaling.amazonaws.com\",\"requestParameters\":{\"DescribeLaunchTemplateVersionsRequest\":{\"LaunchTemplateVersion\":{\"tag\":1,\"content\":\"$Latest\"},\"LaunchTemplateId\":\"lt-0f20d9a64c382e6b6\"}},\"responseElements\":null,\"requestID\":\"6eeedbe9-4196-45b1-82b6-4449366a1610\",\"eventID\":\"252172ff-2238-4086-ae79-aa6ad366ad20\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"420228061920\",\"eventCategory\":\"Management\"}"
        },
        {
            "EventId": "dbb836e7-97a7-4376-996f-3ba87ead67d8",
            "EventName": "ListZonalShifts",
            "ReadOnly": "true",
            "AccessKeyId": "ASIAWDV4LLLQB7AJJQJQ",
            "EventTime": "2026-03-07T15:19:35+00:00",
            "EventSource": "arc-zonal-shift.amazonaws.com",
            "Username": "root",
            "Resources": [],
            "CloudTrailEvent": "{\"eventVersion\":\"1.09\",\"userIdentity\":{\"type\":\"Root\",\"principalId\":\"420228061920\",\"arn\":\"arn:aws:iam::420228061920:root\",\"accountId\":\"420228061920\",\"accessKeyId\":\"ASIAWDV4LLLQB7AJJQJQ\",\"sessionContext\":{\"attributes\":{\"creationDate\":\"2026-03-07T11:51:48Z\",\"mfaAuthenticated\":\"true\"}}},\"eventTime\":\"2026-03-07T15:19:35Z\",\"eventSource\":\"arc-zonal-shift.amazonaws.com\",\"eventName\":\"ListZonalShifts\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"154.47.30.106\",\"userAgent\":\"Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0\",\"requestParameters\":null,\"responseElements\":null,\"requestID\":\"55a39f4f-3e26-4a01-88ac-9a78fada9642\",\"eventID\":\"dbb836e7-97a7-4376-996f-3ba87ead67d8\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"420228061920\",\"eventCategory\":\"Management\",\"tlsDetails\":{\"clientProvidedHostHeader\":\"arc-zonal-shift.ap-northeast-1.amazonaws.com\"},\"sessionCredentialFromConsole\":\"true\"}"
        },
        {
            "EventId": "bbb50c11-7a5b-49fe-91f4-5281b6252edc",
            "EventName": "DescribeLaunchTemplateVersions",
            "ReadOnly": "true",
            "AccessKeyId": "ASIAWDV4LLLQLY2NV2CU",
            "EventTime": "2026-03-07T15:19:25+00:00",
            "EventSource": "ec2.amazonaws.com",
            "Username": "AutoScaling",
            "Resources": [
                {
                    "ResourceType": "AWS::EC2::LaunchTemplate",
                    "ResourceName": "lt-0f20d9a64c382e6b6"
                }
            ],
            "CloudTrailEvent": "{\"eventVersion\":\"1.11\",\"userIdentity\":{\"type\":\"AssumedRole\",\"principalId\":\"AROAWDV4LLLQC2WCMMTUR:AutoScaling\",\"arn\":\"arn:aws:sts::420228061920:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling\",\"accountId\":\"420228061920\",\"accessKeyId\":\"ASIAWDV4LLLQLY2NV2CU\",\"sessionContext\":{\"sessionIssuer\":{\"type\":\"Role\",\"principalId\":\"AROAWDV4LLLQC2WCMMTUR\",\"arn\":\"arn:aws:iam::420228061920:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling\",\"accountId\":\"420228061920\",\"userName\":\"AWSServiceRoleForAutoScaling\"},\"attributes\":{\"creationDate\":\"2026-03-07T15:12:33Z\",\"mfaAuthenticated\":\"false\"}},\"invokedBy\":\"autoscaling.amazonaws.com\"},\"eventTime\":\"2026-03-07T15:19:25Z\",\"eventSource\":\"ec2.amazonaws.com\",\"eventName\":\"DescribeLaunchTemplateVersions\",\"awsRegion\":\"ap-northeast-1\",\"sourceIPAddress\":\"autoscaling.amazonaws.com\",\"userAgent\":\"autoscaling.amazonaws.com\",\"requestParameters\":{\"DescribeLaunchTemplateVersionsRequest\":{\"LaunchTemplateVersion\":{\"tag\":1,\"content\":\"$Latest\"},\"LaunchTemplateId\":\"lt-0f20d9a64c382e6b6\"}},\"responseElements\":null,\"requestID\":\"76d3b3fa-6bfe-43aa-9d00-fed581170878\",\"eventID\":\"bbb50c11-7a5b-49fe-91f4-5281b6252edc\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\"420228061920\",\"eventCategory\":\"Management\"}"
        }
    ],
    "NextToken": "Bozgw/0w1BeRZFTzOsrtgPZOH/Ce1KQv9NR+xqNszSPgz7u4kEtxvoCIU3Rzwv1wM9qZeHloV9lzXeqt3TPZ0A=="
}

------------------------------------------------------------------------

### TGW Corridor Proof

``` bash
aws ec2 describe-transit-gateway-attachments --region ap-northeast-1

######################################################################
{
    "TransitGatewayAttachments": [
        {
            "TransitGatewayAttachmentId": "tgw-attach-05cc331c9a7835b14",
            "TransitGatewayId": "tgw-04fcb36a59fc568fb",
            "TransitGatewayOwnerId": "420228061920",
            "ResourceOwnerId": "420228061920",
            "ResourceType": "peering",
            "ResourceId": "tgw-0ba46950aee4956a2",
            "State": "available",
            "Association": {
                "TransitGatewayRouteTableId": "tgw-rtb-060b6098ddb71c583",
                "State": "associated"
            },
            "CreationTime": "2026-03-07T12:50:51+00:00",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "shinjuku-accepter-for-brazil"
                }
            ]
        },
        {
            "TransitGatewayAttachmentId": "tgw-attach-09ced08005c5213a9",
            "TransitGatewayId": "tgw-04fcb36a59fc568fb",
            "TransitGatewayOwnerId": "420228061920",
            "ResourceOwnerId": "420228061920",
            "ResourceType": "vpc",
            "ResourceId": "vpc-0f6f8f724a69a4041",
            "State": "available",
            "Association": {
                "TransitGatewayRouteTableId": "tgw-rtb-060b6098ddb71c583",
                "State": "associated"
            },
            "CreationTime": "2026-03-07T13:04:31+00:00",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "shinjuku-attach-tokyo-vpc01"
                }
            ]
        }
    ]
}




aws ec2 describe-transit-gateway-attachments --region sa-east-1
```
$ aws ec2 describe-transit-gateway-attachments --region sa-east-1
     {
            "TransitGatewayAttachmentId": "tgw-attach-05cc331c9a7835b14",
            "TransitGatewayId": "tgw-0ba46950aee4956a2",
            "TransitGatewayOwnerId": "420228061920",
            "ResourceOwnerId": "420228061920",
            "ResourceType": "peering",
            "ResourceId": "tgw-04fcb36a59fc568fb",
            "State": "available",
            "Association": {
                "TransitGatewayRouteTableId": "tgw-rtb-0fddcd9b16033f915",
                "State": "associated"
            },
            "CreationTime": "2026-03-07T12:50:40+00:00",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "liberdade-to-shinjuku-peer"
                }
            ]
        },
        {
            "TransitGatewayAttachmentId": "tgw-attach-0059b01da16892482",
            "TransitGatewayId": "tgw-0ba46950aee4956a2",
            "TransitGatewayOwnerId": "420228061920",
            "ResourceOwnerId": "420228061920",
            "ResourceType": "vpc",
            "ResourceId": "vpc-0ed9adce14f27ae7a",
            "State": "available",
            "Association": {
                "TransitGatewayRouteTableId": "tgw-rtb-0fddcd9b16033f915",
                "State": "associated"
            },
            "CreationTime": "2026-03-07T12:50:41+00:00",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "liberdade-attach-sp-vpc01"
                }
            ]
        }
    ]


------------------------------------------------------------------------

### S3 Logging Verification

``` bash
s3 ls s3://medical-vault-audit-logs-sprint3-v1-200819971986/ --region=ap-northeast-1
                           PRE AWSLogs/

aws s3 ls s3://medical-vault-audit-logs-sprint3-v1-200819971986/AWSLogs/ --recursive
```
2026-03-07 13:41:21          0 AWSLogs/420228061920/CloudTrail-Digest/
2026-03-07 14:07:50        367 AWSLogs/420228061920/CloudTrail-Digest/ap-northeast-1/2026/03/07/420228061920_CloudTrail-Digest_ap-northeast-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:07:42       1679 AWSLogs/420228061920/CloudTrail-Digest/ap-northeast-1/2026/03/07/420228061920_CloudTrail-Digest_ap-northeast-1_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 14:07:37        372 AWSLogs/420228061920/CloudTrail-Digest/ap-northeast-2/2026/03/07/420228061920_CloudTrail-Digest_ap-northeast-2_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:07:37        735 AWSLogs/420228061920/CloudTrail-Digest/ap-northeast-2/2026/03/07/420228061920_CloudTrail-Digest_ap-northeast-2_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 14:08:03        366 AWSLogs/420228061920/CloudTrail-Digest/ap-northeast-3/2026/03/07/420228061920_CloudTrail-Digest_ap-northeast-3_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:07:40        733 AWSLogs/420228061920/CloudTrail-Digest/ap-northeast-3/2026/03/07/420228061920_CloudTrail-Digest_ap-northeast-3_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 14:07:20        372 AWSLogs/420228061920/CloudTrail-Digest/ap-south-1/2026/03/07/420228061920_CloudTrail-Digest_ap-south-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:07:42        739 AWSLogs/420228061920/CloudTrail-Digest/ap-south-1/2026/03/07/420228061920_CloudTrail-Digest_ap-south-1_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 14:08:04        371 AWSLogs/420228061920/CloudTrail-Digest/ap-southeast-1/2026/03/07/420228061920_CloudTrail-Digest_ap-southeast-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:07:53        739 AWSLogs/420228061920/CloudTrail-Digest/ap-southeast-1/2026/03/07/420228061920_CloudTrail-Digest_ap-southeast-1_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 14:08:20        374 AWSLogs/420228061920/CloudTrail-Digest/ap-southeast-2/2026/03/07/420228061920_CloudTrail-Digest_ap-southeast-2_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:08:21        738 AWSLogs/420228061920/CloudTrail-Digest/ap-southeast-2/2026/03/07/420228061920_CloudTrail-Digest_ap-southeast-2_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 14:07:37        377 AWSLogs/420228061920/CloudTrail-Digest/ca-central-1/2026/03/07/420228061920_CloudTrail-Digest_ca-central-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:07:36        738 AWSLogs/420228061920/CloudTrail-Digest/ca-central-1/2026/03/07/420228061920_CloudTrail-Digest_ca-central-1_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 14:08:32        377 AWSLogs/420228061920/CloudTrail-Digest/eu-central-1/2026/03/07/420228061920_CloudTrail-Digest_eu-central-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:08:28        744 AWSLogs/420228061920/CloudTrail-Digest/eu-central-1/2026/03/07/420228061920_CloudTrail-Digest_eu-central-1_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 14:08:20        375 AWSLogs/420228061920/CloudTrail-Digest/eu-north-1/2026/03/07/420228061920_CloudTrail-Digest_eu-north-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:08:20        738 AWSLogs/420228061920/CloudTrail-Digest/eu-north-1/2026/03/07/420228061920_CloudTrail-Digest_eu-north-1_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 14:07:47        373 AWSLogs/420228061920/CloudTrail-Digest/eu-west-1/2026/03/07/420228061920_CloudTrail-Digest_eu-west-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:07:52        736 AWSLogs/420228061920/CloudTrail-Digest/eu-west-1/2026/03/07/420228061920_CloudTrail-Digest_eu-west-1_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 14:07:40        375 AWSLogs/420228061920/CloudTrail-Digest/eu-west-2/2026/03/07/420228061920_CloudTrail-Digest_eu-west-2_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:07:38        741 AWSLogs/420228061920/CloudTrail-Digest/eu-west-2/2026/03/07/420228061920_CloudTrail-Digest_eu-west-2_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 14:08:05        374 AWSLogs/420228061920/CloudTrail-Digest/eu-west-3/2026/03/07/420228061920_CloudTrail-Digest_eu-west-3_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:08:04        741 AWSLogs/420228061920/CloudTrail-Digest/eu-west-3/2026/03/07/420228061920_CloudTrail-Digest_eu-west-3_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 14:08:08        373 AWSLogs/420228061920/CloudTrail-Digest/sa-east-1/2026/03/07/420228061920_CloudTrail-Digest_sa-east-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:08:17       1526 AWSLogs/420228061920/CloudTrail-Digest/sa-east-1/2026/03/07/420228061920_CloudTrail-Digest_sa-east-1_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 14:07:21        372 AWSLogs/420228061920/CloudTrail-Digest/us-east-1/2026/03/07/420228061920_CloudTrail-Digest_us-east-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:07:31       2005 AWSLogs/420228061920/CloudTrail-Digest/us-east-1/2026/03/07/420228061920_CloudTrail-Digest_us-east-1_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 14:08:09        370 AWSLogs/420228061920/CloudTrail-Digest/us-east-2/2026/03/07/420228061920_CloudTrail-Digest_us-east-2_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:07:57        736 AWSLogs/420228061920/CloudTrail-Digest/us-east-2/2026/03/07/420228061920_CloudTrail-Digest_us-east-2_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 14:07:28        371 AWSLogs/420228061920/CloudTrail-Digest/us-west-1/2026/03/07/420228061920_CloudTrail-Digest_us-west-1_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:07:43        738 AWSLogs/420228061920/CloudTrail-Digest/us-west-1/2026/03/07/420228061920_CloudTrail-Digest_us-west-1_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 14:07:46        372 AWSLogs/420228061920/CloudTrail-Digest/us-west-2/2026/03/07/420228061920_CloudTrail-Digest_us-west-2_medical-global-trail_ap-northeast-1_20260307T134121Z.json.gz
2026-03-07 15:07:48        829 AWSLogs/420228061920/CloudTrail-Digest/us-west-2/2026/03/07/420228061920_CloudTrail-Digest_us-west-2_medical-global-trail_ap-northeast-1_20260307T144121Z.json.gz
2026-03-07 13:41:21          0 AWSLogs/420228061920/CloudTrail/
2026-03-07 13:46:31       7103 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1350Z_Rfqu67OqV4yoGi1D.json.gz
2026-03-07 13:51:22      12086 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1355Z_ScARf8ingRDaudUy.json.gz
2026-03-07 13:56:23      13965 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1400Z_AmsalGiYC4kErIwo.json.gz
2026-03-07 14:01:24      10551 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1405Z_3rzopinxQKL71kmH.json.gz
2026-03-07 14:05:57       1226 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1405Z_l1kgicBLt00WfnYj.json.gz
2026-03-07 14:07:34      10314 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1410Z_IN5BAvlL9NQJzyNo.json.gz
2026-03-07 14:12:24      14877 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1415Z_BDR3c3okImqkaxxx.json.gz
2026-03-07 14:17:14      13644 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1420Z_lLdqFsYAlULBvU9L.json.gz
2026-03-07 14:22:05       5036 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1425Z_i0pmSqm0NmimV10t.json.gz
2026-03-07 14:23:59       1075 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1425Z_isHuwPlYRlOvTSpH.json.gz
2026-03-07 14:27:05      10446 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1430Z_aFG96OYgZ9C0iFAx.json.gz
2026-03-07 14:32:06      12791 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1435Z_3yE20FAvGQL8ofIQ.json.gz
2026-03-07 14:36:57      10598 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1440Z_GriU9iTbFyp8mWll.json.gz
2026-03-07 14:41:46      13538 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1445Z_en3RgM39pbqznBfI.json.gz
2026-03-07 14:47:27      21850 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1450Z_bzl7mRIjzWYvyfOH.json.gz
2026-03-07 14:52:17      11367 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1455Z_7Mxff0yEpe2EfKMW.json.gz
2026-03-07 14:57:18      14768 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1500Z_Cv1QwTpWRgSiqDgu.json.gz
2026-03-07 15:02:08      13781 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1505Z_TfuVZIRXltI8r4Hg.json.gz
2026-03-07 15:06:59      14434 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1510Z_9zPViUdFOkrDTe2L.json.gz
2026-03-07 15:11:59      18743 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1515Z_BmzSNVT9UVMygzyk.json.gz
2026-03-07 15:16:49      14783 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1520Z_cX3ZdQPNtQCLMtzj.json.gz
2026-03-07 15:21:40       9030 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1525Z_TZaVx7zFEOpPU2Um.json.gz
2026-03-07 15:26:30      11706 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1530Z_DGyPd4rFjrCPGK02.json.gz
2026-03-07 15:31:21      12570 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1535Z_BBoc2M7y6yGAJHJp.json.gz
2026-03-07 15:36:12      13728 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1540Z_adwfNTZYQhOJNwyg.json.gz
2026-03-07 15:41:02      16788 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1545Z_weGChS8ENNuDQrpn.json.gz
2026-03-07 15:46:02       8702 AWSLogs/420228061920/CloudTrail/ap-northeast-1/2026/03/07/420228061920_CloudTrail_ap-northeast-1_20260307T1550Z_gEEiT2Lsm0UdC7d3.json.gz
2026-03-07 13:49:08       1952 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1350Z_bCoHXy0xFYwgo9A8.json.gz
2026-03-07 13:53:58       2759 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1355Z_UKmJ9HhZDaKJNVPp.json.gz
2026-03-07 13:58:59       1855 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1400Z_IPDiDDGC22NyxSuo.json.gz
2026-03-07 14:03:59       1715 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1405Z_2typIHsXBFBi43IZ.json.gz
2026-03-07 14:09:00       2045 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1410Z_Wg30BQnK92ARjnFq.json.gz
2026-03-07 14:14:01       2919 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1415Z_4u8FzjeVOiimzmUs.json.gz
2026-03-07 14:19:01       1852 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1420Z_LnZO90cn2srIPJ3y.json.gz
2026-03-07 14:24:03       2760 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1425Z_BjBgKLjWkrgy32HS.json.gz
2026-03-07 14:29:04       4664 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1430Z_9lUHKcuj3CukNmdl.json.gz
2026-03-07 14:34:05       2122 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1435Z_vnL04lfx4ExASrDn.json.gz
2026-03-07 14:38:55       4724 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1440Z_zP5lznQBdA8BlPo2.json.gz
2026-03-07 14:44:06       1724 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1445Z_3xDEII4B68KNkLdR.json.gz
2026-03-07 14:48:57       3809 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1450Z_OeaT1WZP26JFLvjL.json.gz
2026-03-07 14:54:07       1723 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1455Z_LPTXQqxmrUMsTlkP.json.gz
2026-03-07 14:58:58       1852 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1500Z_OYeyK92Oq6V7yAzT.json.gz
2026-03-07 15:03:58       1454 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1500Z_jNgPEKok2yc3r8BS.json.gz
2026-03-07 15:06:10        887 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1505Z_2UrziktDLNNmlyIk.json.gz
2026-03-07 15:08:19        652 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1505Z_GJx84cisdp7wOArK.json.gz
2026-03-07 15:09:00       2049 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1510Z_6Ua3y5CW9X1I5lxM.json.gz
2026-03-07 15:14:00       2787 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1515Z_UJbxzwtkbbEK1YAl.json.gz
2026-03-07 15:19:01       1855 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1520Z_jEpIOv7m72RisNOB.json.gz
2026-03-07 15:24:02       4297 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1525Z_FuiLakwTAy7lAhvL.json.gz
2026-03-07 15:29:03       3432 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1530Z_dLDVk47uELFnj2fe.json.gz
2026-03-07 15:33:54       3516 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1535Z_omwCwcaMhjdVkWet.json.gz
2026-03-07 15:38:55       4175 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1540Z_ZDnW6MZ2y0qD5rWP.json.gz
2026-03-07 15:44:05       1736 AWSLogs/420228061920/CloudTrail/sa-east-1/2026/03/07/420228061920_CloudTrail_sa-east-1_20260307T1545Z_WnYAQxvNeuHnAwN8.json.gz
2026-03-07 13:44:33        625 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1345Z_2GYySUSG2XhKnNcN.json.gz
2026-03-07 13:47:56        590 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1345Z_fSAAevWpyLyXPyDV.json.gz
2026-03-07 13:49:44       5448 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1350Z_bWZroXgjMdms29zq.json.gz
2026-03-07 13:53:16       2122 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1355Z_vYcECyUE5zY6m0ss.json.gz
2026-03-07 13:57:55       2399 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1400Z_BNNTVF084PWgx2NP.json.gz
2026-03-07 14:03:17       2299 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1400Z_EdpTJSK40U0iLTaC.json.gz
2026-03-07 14:03:16       3745 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1405Z_9pNam3Nz3ZszB7E3.json.gz
2026-03-07 14:13:18        784 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1410Z_Fhp0IFd1hRUTBVkp.json.gz
2026-03-07 14:09:56       6276 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1410Z_vzdtfJkSOoDduMYj.json.gz
2026-03-07 14:15:38       1940 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1420Z_Vt1FEQFYP9MVfzi7.json.gz
2026-03-07 14:20:38       5517 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1420Z_X6fbhelmzb9LSawG.json.gz
2026-03-07 14:21:49        668 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1425Z_3t6mtS6hC1xWjsaz.json.gz
2026-03-07 14:33:10        621 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1430Z_6rx2lFKVO9w0o6qI.json.gz
2026-03-07 14:33:20       1460 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1430Z_C4sxsYwYx5hevTtF.json.gz
2026-03-07 14:27:59       2400 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1430Z_eYh2L68kPp1VoBbK.json.gz
2026-03-07 14:33:11       4396 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1435Z_JiGzwqE9XM3XQAPb.json.gz
2026-03-07 14:40:22       2628 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1440Z_6NDwAZS2JLhaHmqt.json.gz
2026-03-07 14:39:41       5817 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1440Z_Z86tJFZVJ4DRseFE.json.gz
2026-03-07 14:44:32        865 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1445Z_1VR5Y1c6la2PA8rP.json.gz
2026-03-07 14:50:03        588 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1450Z_TrYuoLm6cdDfIP4r.json.gz
2026-03-07 14:50:03       7850 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1450Z_aAlc9MH9l7QziV4Q.json.gz
2026-03-07 14:56:05       2394 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1500Z_4Fl7CBlixNvvBkuD.json.gz
2026-03-07 14:58:14       1281 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1500Z_ha1CEd6MUe6vpgH1.json.gz
2026-03-07 15:01:55       6692 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1505Z_anP9K51KWIZWge69.json.gz
2026-03-07 15:10:26       1777 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1510Z_6BoozJWG3v8b5syk.json.gz
2026-03-07 15:07:57       8633 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1510Z_jH8lmUx2ZwqFeNVX.json.gz
2026-03-07 15:11:48        702 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1510Z_tk8tphITKC3gqK40.json.gz
2026-03-07 15:13:24       1784 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1515Z_XxTe3Kztx6NWX21y.json.gz
2026-03-07 15:12:58       6143 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1515Z_dBiNgi7VOYQrLTOI.json.gz
2026-03-07 15:18:09       4257 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1520Z_EtwPNcyZEOCb8YPH.json.gz
2026-03-07 15:23:16       1458 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1520Z_JKdP0WdiF0IVTIay.json.gz
2026-03-07 15:20:49       1361 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1520Z_f81Vzw50ZlzVudyW.json.gz
2026-03-07 15:23:09       6591 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1525Z_cRemrV6i1rAWUQMh.json.gz
2026-03-07 15:26:19        798 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1530Z_IAMIFb3CDdxORfGt.json.gz
2026-03-07 15:28:20       4381 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1530Z_dBpQ0eBlvF48hZ1N.json.gz
2026-03-07 15:33:10       5889 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1535Z_0FzuLbSAuKGp5NZl.json.gz
2026-03-07 15:33:17       1783 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1535Z_LjZOblXtFErLcCLv.json.gz
2026-03-07 15:34:20       1212 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1535Z_kyERCZqZqTkmwLHY.json.gz
2026-03-07 15:38:21       4849 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1540Z_1J7BS256Kb7n8S46.json.gz
2026-03-07 15:40:21       2640 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1540Z_4cqePd7FxeOdD7RY.json.gz
2026-03-07 15:43:19       1048 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1540Z_996FHLVwcbK5Of0c.json.gz
2026-03-07 15:43:18        902 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1540Z_wfjbnMpD30lamika.json.gz
2026-03-07 15:43:12       5300 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1545Z_b84D6BnWPaBSZxPf.json.gz
2026-03-07 15:47:33        799 AWSLogs/420228061920/CloudTrail/us-east-1/2026/03/07/420228061920_CloudTrail_us-east-1_20260307T1550Z_BTOAQXGRQvvuoUoI.json.gz
2026-03-07 14:31:10       1662 AWSLogs/420228061920/CloudTrail/us-west-2/2026/03/07/420228061920_CloudTrail_us-west-2_20260307T1430Z_5bfmNN60jreWMiPI.json.gz
2026-03-07 14:59:24       1646 AWSLogs/420228061920/CloudTrail/us-west-2/2026/03/07/420228061920_CloudTrail_us-west-2_20260307T1455Z_UH4iTn2PMkFbxlFj.json.gz
------------------------------------------------------------------------

## Malgus Verification Scripts

Scripts included:

-   malgus_residency_proof.py
-   malgus_tgw_corridor_proof.py
-   malgus_cloudtrail_last_changes.py
-   malgus_waf_summary.py
-   malgus_cloudfront_log_explainer.py

------------------------------------------------------------------------

## Deliverable B --- Auditor Narrative

This architecture ensures APPI compliance by keeping all PHI strictly
within Japan while still enabling global access.

Tokyo hosts the only RDS instance, making it authoritative, while São
Paulo operates as stateless compute that never stores PHI locally.

A Transit Gateway corridor provides a controlled, auditable path between
regions without exposing data to the public internet.

CloudFront provides a single secure entry point worldwide, WAF protects
the edge, CloudTrail records all changes immutably, and S3 stores logs
for forensic analysis.

Together these controls ensure performance, resilience, and legal
compliance.

------------------------------------------------------------------------

## What This Lab Teaches

LAB3 demonstrates how to:

-   Design legally constrained global systems
-   Enforce data residency
-   Build audit-ready architectures
-   Validate behavior through logs
-   Support compliance teams
-   Communicate clearly with auditors
