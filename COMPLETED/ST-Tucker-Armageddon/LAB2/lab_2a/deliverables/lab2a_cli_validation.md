### Lab 2A Command Line Verification

### Environment variables.


### Set region variable for AWS CLI commands.

```
REGION="us-east-1"
```
### Get Terraform outputs for later use in CLI validation steps.

ALB_DNS="$(terraform output -raw alb_dns_name)"
CF_DIST_ID="$(terraform output -raw cloudfront_distribution_id)"
CF_DOMAIN="$(terraform output -raw cloudfront_domain_name)"
CF_WAF_ARN="$(terraform output -raw cloudfront_waf_arn)"

### Get WAF name and ID from ARN for later use.

CF_WAF_NAME="$(echo "$CF_WAF_ARN" | awk -F'/' '{print $(NF-1)}')"

### Get WAF ID from ARN for later use.
CF_WAF_ID="$(echo "$CF_WAF_ARN" | awk -F'/' '{print $NF}')"

### Get ALB ARN and SG ID for later use.
ALB_ARN="$(aws elbv2 describe-load-balancers --region "$REGION" \
  --names lab-2a-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)"

### Get the security group ID associated with the ALB for later use.

ALB_SG_ID="$(aws elbv2 describe-load-balancers --region "$REGION" \
  --names lab-2a-alb \
  --query 'LoadBalancers[0].SecurityGroups[0]' --output text)"

```
echo "ALB_DNS=$ALB_DNS"
echo "CF_DIST_ID=$CF_DIST_ID"
echo "CF_DOMAIN=$CF_DOMAIN"
echo "CF_WAF_ARN=$CF_WAF_ARN"
```

1) “VPC is only reachable via CloudFront”
A) Direct ALB access should fail (403)

```
  curl -I https://<ALB_DNS_NAME>
```

Expected: 403 (blocked by missing header)

```
ALB_DNS_NAME="$(terraform output -raw alb_dns_name)"
curl -I https://${ALB_DNS_NAME}
```

[OBSERVATION] I experienced timeouts on this verification step. I suspect it is due to
my security group settings for cloudfront origin-facing prefix list. I will
do further research on this issue. 

- I tried this variation on curl. The end result is the same, but I get a more descriptive error message.

curl -m 10 -sS -I "https://${ALB_DNS}" || true

$ curl -m 10 -sS -I "https://${ALB_DNS}" || true
curl: (28) Connection timed out after 10006 milliseconds

# Prove Security Group is CloudFront  only:

```
echo "ALB_SG_ID=$ALB_SG_ID"
```

ALB_SG_ID=sg-0cdb088e5f6990acd

```
aws ec2 describe-security-groups --region "$REGION" \
  --group-ids "$ALB_SG_ID" \
  --query "SecurityGroups[0].IpPermissions" --output json
```


$ aws ec2 describe-security-groups --region "$REGION" \
>   --group-ids "$ALB_SG_ID" \
>   --query "SecurityGroups[0].IpPermissions" --output json
[
    {
        "IpProtocol": "tcp",
        "FromPort": 443,
        "ToPort": 443,
        "UserIdGroupPairs": [],
        "IpRanges": [],
        "Ipv6Ranges": [],
        "PrefixListIds": [
            {
                "Description": "HTTPS from CloudFront origin-facing prefix list",
                "PrefixListId": "pl-3b927c52"
            }
        ]
    }
]

Show that the prefix list ID matches the one for CloudFront in the region:

```aws ec2 describe-managed-prefix-lists --region "$REGION" \
  --query "PrefixLists[?PrefixListId=='pl-3b927c52'].{Name:PrefixListName,Id:PrefixListId}" --output json
```

$ aws ec2 describe-managed-prefix-lists --region "$REGION" \
>   --query "PrefixLists[?PrefixListId=='pl-3b927c52'].{Name:PrefixListName,Id:PrefixListId}" --output json
[
    {
        "Name": "com.amazonaws.global.cloudfront.origin-facing",
        "Id": "pl-3b927c52"
    }
]

B) CloudFront access should succeed

  ```
  curl -I https://<DOMAIN_NAME>
  ```
  ```
    curl -I https://app.<DOMAIN_NAME>
  ```

Expected: 200/301 → 200

```
curl -I https://devlab405.click
```
```
curl -I https://app.devlab405.click
```


$ curl -I https://devlab405.click
HTTP/2 200 
content-type: text/html; charset=utf-8
content-length: 93
date: Sun, 08 Feb 2026 15:08:34 GMT
server: Werkzeug/3.1.5 Python/3.9.25
x-cache: Miss from cloudfront
via: 1.1 4aeb5ac488d8838bd5a90d099ec4160a.cloudfront.net (CloudFront)
x-amz-cf-pop: HAM50-P4
x-amz-cf-id: HTOI__3rVkebu8hmo3IAqJD5sBC1jTMYyql-SWr9SPQseGqDZ3dWZA=

$ curl -I https://app.devlab405.click
HTTP/2 200 
content-type: text/html; charset=utf-8
content-length: 93
date: Sun, 08 Feb 2026 15:09:56 GMT
server: Werkzeug/3.1.5 Python/3.9.25
x-cache: Miss from cloudfront
via: 1.1 135476f3cf36768013bf532f9055732e.cloudfront.net (CloudFront)
x-amz-cf-pop: HAM50-P4
x-amz-cf-id: VY2UC_B-TH1mGRoBX5-wr8cviHCm8mUD6wOJboHue4Lyxr9GkoXZJA


2) WAF moved to CloudFront

```
  aws wafv2 get-web-acl \
  --name <project>-cf-waf01 \
  --scope CLOUDFRONT \
  --id <WEB_ACL_ID>
```
```
aws wafv2 get-web-acl \
  --name "$CF_WAF_NAME" \
  --scope CLOUDFRONT \
  --id "$CF_WAF_ID" \
  --region us-east-1 \
  --query '{Name:WebACL.Name,ARN:WebACL.ARN,Scope:WebACL.Scope}' \
  --output json
```

$ aws wafv2 get-web-acl \
>   --name "$CF_WAF_NAME" \
>   --scope CLOUDFRONT \
>   --id "$CF_WAF_ID" \
>   --region us-east-1 \
>   --query '{Name:WebACL.Name,ARN:WebACL.ARN,Scope:WebACL.Scope}' \
>   --output json
{
    "Name": "lab-2a-cf-waf01",
    "ARN": "arn:aws:wafv2:us-east-1:<REDACTED>:global/webacl/lab-2a-cf-waf01/7841af75-fad5-41fc-964c-e2964eb3cab4",
    "Scope": null
}

And confirm distribution references it:

```
  aws cloudfront get-distribution \
  --id <DISTRIBUTION_ID> \
  --query "Distribution.DistributionConfig.WebACLId"
```
### A quick grep for "acl" in the distribution config output shows the WebACL ARN is present:
aws cloudfront get-distribution   --id "$CF_DIST_ID"   --query "Distribution.DistributionConfig" | grep -i acl
    "WebACLId": "arn:aws:wafv2:us-east-1:261519058382:global/webacl/lab-2a-cf-waf01/7841af75-fad5-41fc-964c-e2964eb3cab4",

### Show that the WebACL ARN matches the WAF ARN from AWS query output in json format for easier comparison.
$ aws cloudfront get-distribution   --id "$CF_DIST_ID"   --query "Distribution.DistributionConfig" 
{
    "CallerReference": "terraform-20260208130914890200000002",
    "Aliases": {
        "Quantity": 2,
        "Items": [
            "devlab405.click",
            "app.devlab405.click"
        ]
    },
    "DefaultRootObject": "",
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "lab-2a-alb-origin01",
                "DomainName": "lab-2a-alb-158159990.us-east-1.elb.amazonaws.com",
                "OriginPath": "",
                "CustomHeaders": {
                    "Quantity": 1,
                    "Items": [
                        {
                            "HeaderName": "X-Origin-Verify",
                            "HeaderValue": "ziKXCoGCFFyIKp1cp1DqouEXtZZ4Rcjj"
                        }
                    ]
                },
                "CustomOriginConfig": {
                    "HTTPPort": 80,
                    "HTTPSPort": 443,
                    "OriginProtocolPolicy": "https-only",
                    "OriginSslProtocols": {
                        "Quantity": 1,
                        "Items": [
                            "TLSv1.2"
                        ]
                    },
                    "OriginReadTimeout": 30,
                    "OriginKeepaliveTimeout": 5
                },
                "ConnectionAttempts": 3,
                "ConnectionTimeout": 10,
                "OriginShield": {
                    "Enabled": false
                },
                "OriginAccessControlId": ""
            }
        ]
    },
    "OriginGroups": {
        "Quantity": 0
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "lab-2a-alb-origin01",
        "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
        },
        "TrustedKeyGroups": {
            "Enabled": false,
            "Quantity": 0
        },
        "ViewerProtocolPolicy": "redirect-to-https",
        "AllowedMethods": {
            "Quantity": 7,
            "Items": [
                "HEAD",
                "DELETE",
                "POST",
                "GET",
                "OPTIONS",
                "PUT",
                "PATCH"
            ],
            "CachedMethods": {
                "Quantity": 2,
                "Items": [
                    "HEAD",
                    "GET"
                ]
            }
        },
        "SmoothStreaming": false,
        "Compress": false,
        "LambdaFunctionAssociations": {
            "Quantity": 0
        },
        "FunctionAssociations": {
            "Quantity": 0
        },
        "FieldLevelEncryptionId": "",
        "GrpcConfig": {
            "Enabled": false
        },
        "ForwardedValues": {
            "QueryString": true,
            "Cookies": {
                "Forward": "all"
            },
            "Headers": {
                "Quantity": 1,
                "Items": [
                    "*"
                ]
            },
            "QueryStringCacheKeys": {
                "Quantity": 0
            }
        },
        "MinTTL": 0,
        "DefaultTTL": 0,
        "MaxTTL": 0
    },
    "CacheBehaviors": {
        "Quantity": 0
    },
    "CustomErrorResponses": {
        "Quantity": 0
    },
    "Comment": "lab-2a-cf01",
    "Logging": {
        "Enabled": false,
        "IncludeCookies": false,
        "Bucket": "",
        "Prefix": ""
    },
    "PriceClass": "PriceClass_All",
    "Enabled": true,
    "ViewerCertificate": {
        "CloudFrontDefaultCertificate": false,
        "ACMCertificateArn": "arn:aws:acm:us-east-1:261519058382:certificate/2d9b3ae5-67f2-4fdc-b59c-16393ee5b4fe",
        "SSLSupportMethod": "sni-only",
        "MinimumProtocolVersion": "TLSv1.2_2021",
        "Certificate": "arn:aws:acm:us-east-1:261519058382:certificate/2d9b3ae5-67f2-4fdc-b59c-16393ee5b4fe",
        "CertificateSource": "acm"
    },
    "Restrictions": {
        "GeoRestriction": {
            "RestrictionType": "none",
            "Quantity": 0
        }
    },
    "WebACLId": "arn:aws:wafv2:us-east-1:261519058382:global/webacl/lab-2a-cf-waf01/7841af75-fad5-41fc-964c-e2964eb3cab4",
    "HttpVersion": "http2",
    "IsIPV6Enabled": true,
    "ContinuousDeploymentPolicyId": "",
    "Staging": false
}

Expected: WebACL ARN present.

3) chewbacca-growl.com points to CloudFront

```
  dig devlab405.click A +short
```

```
  dig app.devlab405.click A +short
```


$  dig devlab405.click A +short
3.174.98.24
3.174.98.10
3.174.98.118
3.174.98.65

$   dig app.devlab405.click A +short
3.174.98.24
3.174.98.65
3.174.98.10
3.174.98.118

