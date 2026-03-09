1# Confirm hosted zone exists (if managed)

aws route53 list-hosted-zones-by-name 
--dns-name tritechsite.com 
--query "HostedZones[].Id"

{
    "DashboardEntries": [
        {
            "DashboardName": "armageddon-class-vii-dashboard01",
            "DashboardArn": "arn:aws:cloudwatch::420228061920:dashboard/armageddon-class-vii-dashboard01",
            "LastModified": "2026-03-04T20:58:34+00:00",
            "Size": 700
        }
    ]
}



 aws route53 list-hosted-zones-by-name --dns-name tritechsite.com --query "HostedZones[].Id"
[
    "/hostedzone/Z024936810SNP2IVKNJY3"
]

PS C:\Users\User\Documents\TheoWAF\Development\Personal\armageddon\LAB 1\c> aws route53 list-hosted-zones-by-name --dns-name tritechsite.com                           
{
    "HostedZones": [
        {
            "Id": "/hostedzone/Z024936810SNP2IVKNJY3",
            "Name": "tritechsite.com.",
            "CallerReference": "terraform-20260304205527016700000001",
            "Config": {
                "Comment": "Managed by Terraform",
                "PrivateZone": false
            },
            "ResourceRecordSetCount": 5
        }
    ],
    "DNSName": "tritechsite.com",
    "IsTruncated": false,
    "MaxItems": "100"
}

2) Confirm app record exists

aws route53 list-resource-record-sets 
--hosted-zone-id Z024936810SNP2IVKNJY3 
--query "ResourceRecordSets[?Name=='app.tritechsite.com.']"

[
    {
        "Name": "app.tritechsite.com.",
        "Type": "A",
        "AliasTarget": {
            "HostedZoneId": "Z14GRHDCWA56QT",
            "DNSName": "armageddon-class-vii-alb01-866112400.ap-northeast-1.elb.amazonaws.com.",
            "EvaluateTargetHealth": true
        }
    }
]




3) Confirm certificate issued

aws acm describe-certificate 
  --certificate-arn "arn:aws:acm:ap-northeast-1:420228061920:certificate/a179f063-d9a1-4d47-9f70-11588cb8de26"   
  --region ap-northeast-1   
  --query "Certificate.Status" 

  "ISSUED"

 7) Confirm HTTPS works

  curl -I https://app.tritechsite.com

  HTTP/2 200 
HTTP/1.1 200 OK
Date: Wed, 04 Mar 2026 23:02:34 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 93
Connection: keep-alive
Server: Werkzeug/3.1.6 Python/3.9.25
