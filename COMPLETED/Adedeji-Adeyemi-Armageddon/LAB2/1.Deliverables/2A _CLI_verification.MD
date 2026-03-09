Verification CLI (students must prove all 3 requirements)
1) “VPC is only reachable via CloudFront”
A) Direct ALB access should fail (403)
  curl -I https://armageddon-class-vii-alb01-855999183.ap-northeast-1.elb.amazonaws.com

  

  curl: (28) Connection timed out after 10006 milliseconds

  B) CloudFront access should succeed
  curl -I https://tritechsite.com
  curl -I https://app.tritechsite.com

HTTP/1.1 502 Bad Gateway
Content-Type: text/html
Content-Length: 937
Connection: keep-alive
date: Fri, 06 Mar 2026 09:14:48 GMT
X-Cache: Error from cloudfront
Via: 1.1 e48f2ecc56543f17941962794216ee4e.cloudfront.net (CloudFront)
X-Amz-Cf-Pop: CPT51-P2
X-Amz-Cf-Id: v75HHw5CcOLe65TcUSBN4atSRNu3gKDrPolr4asLJbj0hikFB3PqAQ==
$ curl -i https://app.tritechsite.com
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Content-Length: 93
Connection: keep-alive
Date: Fri, 06 Mar 2026 09:16:07 GMT
Server: Werkzeug/3.1.6 Python/3.9.25
X-Cache: Miss from cloudfront
Via: 1.1 419858185e849f344f0f15526567bd40.cloudfront.net (CloudFront)
X-Amz-Cf-Pop: CPT51-P2
X-Amz-Cf-Id: 8P5i9PNlv3ZP6C9oA59_xW94xMU4FZO0Dhuu5NhdVMGd70i-vkXtig==


    <h2>EC2 → RDS Notes App</h2>
    <p>POST /add?note=hello</p>
    <p>GET /list</p>





2) WAF moved to CloudFront
  aws wafv2 get-web-acl 
  --name chewbacca-cf-waf01 
  --scope CLOUDFRONT 
  --region us-east-1
  --id 0d367a7c-0c55-43f3-bbaa-54793ce657d8

{
    "WebACL": {
        "Name": "chewbacca-cf-waf01",
        "Id": "0d367a7c-0c55-43f3-bbaa-54793ce657d8",
        "ARN": "arn:aws:wafv2:us-east-1:420228061920:global/webacl/chewbacca-cf-waf01/0d367a7c-0c55-43f3-bbaa-54793ce657d8",
        "DefaultAction": {
            "Allow": {}
        },
        "Description": "",
        "Rules": [
            {
                "Name": "AWS-AWSManagedRulesCommonRuleSet",
                "Priority": 1,
                "Statement": {
                    "ManagedRuleGroupStatement": {
                        "VendorName": "AWS",
                        "Name": "AWSManagedRulesCommonRuleSet"
                    }
                },
                "OverrideAction": {
                    "None": {}
                },
                "VisibilityConfig": {
                    "SampledRequestsEnabled": true,
                    "CloudWatchMetricsEnabled": true,
                    "MetricName": "AWSManagedRulesCommonRuleSetMetric"
                }
            }
        ],
        "VisibilityConfig": {
            "SampledRequestsEnabled": true,
            "CloudWatchMetricsEnabled": true,
            "MetricName": "chewbacca-cf-waf-main-metric"
        },
        "Capacity": 700,
        "ManagedByFirewallManager": false,
        "LabelNamespace": "awswaf:420228061920:webacl:chewbacca-cf-waf01:",
        "RetrofittedByFirewallManager": false,
        "OnSourceDDoSProtectionConfig": {
            "ALBLowReputationMode": "ACTIVE_UNDER_DDOS"
        }
    },
    "LockToken": "ef728630-e252-4719-b6bb-31f0f6f81ec0"
}

And confirm distribution references it:
  aws cloudfront get-distribution  
  --id E167X8PDVT7G9M 
  --query "Distribution.DistributionConfig.WebACLId"

"arn:aws:wafv2:us-east-1:420228061920:global/webacl/chewbacca-cf-waf01/0d367a7c-0c55-43f3-bbaa-54793ce657d8"

  3) tritechsite.com points to CloudFront
   dig tritechsite.com A +short
  dig app.tritechsite.com A +short

  nslookup  tritechsite.com  
  nslookup  app.tritechsite.com  

 52.85.25.80
          52.85.25.79
          52.85.25.86
          52.85.25.72