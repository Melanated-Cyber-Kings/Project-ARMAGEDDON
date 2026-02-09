
# SEIR Gate: Secrets + EC2 Role Verification
# This was run on EC2 instance via SSM Session Manager with the following environment variables set:

sh-5.2$ REQUIRE_ROTATION=false \
CHECK_SECRET_VALUE_READ=true \
EXPECTED_ROLE_NAME="lab-1c-ec2-secrets-role" \
REGION=ap-northeast-1 \
INSTANCE_ID=i-0c383ff79071f0dfe \
SECRET_ID="lab-1c/rds/mysql" \
./gate_secrets_and_role.sh

=== SEIR Gate: Secrets + EC2 Role Verification ===
Timestamp (UTC): 2026-02-06T18:47:24Z
Region:          ap-northeast-1
Instance ID:     i-0c383ff79071f0dfe
Secret ID:       lab-1c/rds/mysql
Resolved Role:   lab-1c-ec2-secrets-role
Caller ARN:      arn:aws:sts::<REDACTED>:assumed-role/lab-1c-ec2-secrets-role/i-0c383ff79071f0dfe
-----------------------------------------------
PASS: aws sts get-caller-identity succeeded (credentials OK).
PASS: secret exists and is describable (lab-1c/rds/mysql).
INFO: rotation requirement disabled (REQUIRE_ROTATION=false).
PASS: no resource policy found (OK) or not applicable (lab-1c/rds/mysql).
PASS: instance has IAM instance profile attached (i-0c383ff79071f0dfe).
PASS: resolved instance profile -> role (lab-1c-ec2-secrets-profile -> lab-1c-ec2-secrets-role).
PASS: resolved role matches EXPECTED_ROLE_NAME (lab-1c-ec2-secrets-role).
PASS: current caller is running as expected role (lab-1c-ec2-secrets-role).
PASS: on-instance role can describe secret (lab-1c/rds/mysql).
PASS: on-instance role can read secret value (lab-1c/rds/mysql) (value not printed).

RESULT: PASS
===============================================

Wrote: gate_result.json

# This time the script was run on the same EC2 instance but with a REEQUIRE_ROTATION=true to check the rotation requirement logic:

sh-5.2$ REQUIRE_ROTATION=true \
CHECK_SECRET_VALUE_READ=true \
EXPECTED_ROLE_NAME="lab-1c-ec2-secrets-role" \
REGION=ap-northeast-1 \
INSTANCE_ID=i-0c383ff79071f0dfe \
SECRET_ID="lab-1c/rds/mysql" \
./gate_secrets_and_role.sh

=== SEIR Gate: Secrets + EC2 Role Verification ===
Timestamp (UTC): 2026-02-06T18:50:08Z
Region:          ap-northeast-1
Instance ID:     i-0c383ff79071f0dfe
Secret ID:       lab-1c/rds/mysql
Resolved Role:   lab-1c-ec2-secrets-role
Caller ARN:      arn:aws:sts::<REDACTED>:assumed-role/lab-1c-ec2-secrets-role/i-0c383ff79071f0dfe
-----------------------------------------------
PASS: aws sts get-caller-identity succeeded (credentials OK).
PASS: secret exists and is describable (lab-1c/rds/mysql).
PASS: secret rotation enabled (lab-1c/rds/mysql).
PASS: no resource policy found (OK) or not applicable (lab-1c/rds/mysql).
PASS: instance has IAM instance profile attached (i-0c383ff79071f0dfe).
PASS: resolved instance profile -> role (lab-1c-ec2-secrets-profile -> lab-1c-ec2-secrets-role).
PASS: resolved role matches EXPECTED_ROLE_NAME (lab-1c-ec2-secrets-role).
PASS: current caller is running as expected role (lab-1c-ec2-secrets-role).
PASS: on-instance role can describe secret (lab-1c/rds/mysql).
PASS: on-instance role can read secret value (lab-1c/rds/mysql) (value not printed).

RESULT: PASS
===============================================

Wrote: gate_result.json

# Confirm WAF logging is enabled.

## Setup variables for WAF log verification:

REGION=ap-northeast-1
DOMAIN_APEX="devlab405.click"
DOMAIN_APP="app.devlab405.click"

WEB_ACL_ARN="arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048"
WAF_LOG_GROUP="aws-waf-logs-lab-1c-webacl"

```
aws wafv2 get-logging-configuration \
  --region "$REGION" \
  --resource-arn "$WEB_ACL_ARN" \
  --output json 
```

$ aws wafv2 get-logging-configuration \
  --region "$REGION" \
  --resource-arn "$WEB_ACL_ARN" \
  --output json 

{
    "LoggingConfiguration": {
        "ResourceArn": "arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048",
        "LogDestinationConfigs": [
            "arn:aws:logs:ap-northeast-1:261519058382:log-group:aws-waf-logs-lab-1c-webacl"
        ],
        "ManagedByFirewallManager": false,
        "LogType": "WAF_LOGS",
        "LogScope": "CUSTOMER"
    }
}

## Confirm WAF log outout destination is correct:
```
aws wafv2 get-logging-configuration \
  --region "$REGION" \
  --resource-arn "$WEB_ACL_ARN" \
  --query 'LoggingConfiguration.LogDestinationConfigs | length(@)' \
  --output text | tee deliverables/bonus_e_A_log_destination_count.txt
```

[NOTE: The output should be 1, indicating exactly one log destination is configured.]

$ aws wafv2 get-logging-configuration \
>   --region "$REGION" \
>   --resource-arn "$WEB_ACL_ARN" \
>   --query 'LoggingConfiguration.LogDestinationConfigs | length(@)' \
>   --output text 
1

## Generate traffic to the ALB to confirm WAF logging is working:
```
curl -I "https://${DOMAIN_APEX}/" | tee deliverables/bonus_e_B_curl_apex_headers.txt
```

```
curl -I "https://${DOMAIN_APP}/"  | tee deliverables/bonus_e_B_curl_app_headers.txt
```

[NOTE: The response headers should include "x-amz-waf-debug" indicating the request was processed by WAF and logged.]

$ curl -I "https://${DOMAIN_APEX}/" | tee deliverables/bonus_e_B_curl_apex_headers.txt
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
curl: (60) SSL: no alternative certificate subject name matches target host name 'devlab405.click'
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.

$ curl -I "https://${DOMAIN_APP}/"  | tee deliverables/bonus_e_B_curl_app_headers.txt
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0    93    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
HTTP/2 200 
date: Fri, 06 Feb 2026 20:23:20 GMT
content-type: text/html; charset=utf-8
content-length: 93
server: Werkzeug/3.1.5 Python/3.9.2

## I selected CloudWatch Logs as the destination for WAF logs, so I can also confirm that the logs are being delivered there:

# List recent log streams in the WAF log group:
```
aws logs describe-log-streams \
  --region "$REGION" \
  --log-group-name "$WAF_LOG_GROUP" \
  --order-by "LastEventTime" \
  --descending \
  --limit 10 \
  --output json | tee deliverables/bonus_e_C_waf_log_streams.json
```

$ aws logs describe-log-streams \
>   --region "$REGION" \
>   --log-group-name "$WAF_LOG_GROUP" \
>   --order-by "LastEventTime" \
>   --descending \
>   --limit 10 \
>   --output json 
{
    "logStreams": [
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "creationTime": 1770399832695,
            "firstEventTimestamp": 1770399821031,
            "lastEventTimestamp": 1770408084521,
            "lastIngestionTime": 1770408098926,
            "uploadSequenceToken": "49039859660984452524257190578781471588412059741186928570",
            "arn": "arn:aws:logs:ap-northeast-1:261519058382:log-group:aws-waf-logs-lab-1c-webacl:log-stream:ap-northeast-1_lab-1c-waf_0",
            "storedBytes": 0
        }
    ]
}

## Get recent log events from the most recent log stream:

```
aws logs filter-log-events \
  --region "$REGION" \
  --log-group-name "$WAF_LOG_GROUP" \
  --log-stream-names "ap-northeast-1_lab-1c-waf_0" \
  --limit 20 \
  --output json | tee deliverables/bonus_e_D_waf_log_events.json
```

$ aws logs filter-log-events \
>   --region "$REGION" \
>   --log-group-name "$WAF_LOG_GROUP" \
>   --log-stream-names "ap-northeast-1_lab-1c-waf_0" \
>   --limit 20 \
>   --output json | tee deliverables/bonus_e_D_waf_log_events.json
{
    "events": [
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399821031,
            "message": "{\"timestamp\":1770399821031,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"AWSManagedRulesCommonRuleSet\",\"terminatingRuleType\":\"MANAGED_RULE_GROUP\",\"action\":\"BLOCK\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":{\"ruleId\":\"NoUserAgent_HEADER\",\"action\":\"BLOCK\",\"ruleMatchDetails\":null},\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"103.252.89.75\",\"country\":\"DE\",\"headers\":[{\"name\":\"Host\",\"value\":\"54.64.241.248\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"GET\",\"requestId\":\"1-6986284d-1f7a6171658ca01421da9814\",\"fragment\":\"\",\"scheme\":\"http\",\"host\":\"54.64.241.248\"},\"labels\":[{\"name\":\"awswaf:managed:aws:core-rule-set:NoUserAgent_Header\"}]}",
            "ingestionTime": 1770399832771,
            "eventId": "39481235308336547776088024681269217727603437845425225728"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399914125,
            "message": "{\"timestamp\":1770399914125,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"5.75.224.239\",\"country\":\"DE\",\"headers\":[{\"name\":\"Host\",\"value\":\"devlab405.click\"},{\"name\":\"Sec-Fetch-Mode\",\"value\":\"navigate\"},{\"name\":\"Sec-Fetch-User\",\"value\":\"?1\"},{\"name\":\"Sec-Fetch-Dest\",\"value\":\"document\"},{\"name\":\"Accept-Encoding\",\"value\":\"gzip, deflate, br\"},{\"name\":\"Accept-Language\",\"value\":\"en-US,en;q=0.9,de;q=0.8,fr;q=0.7,nl;q=0.6,lb;q=0.5,es;q=0.4,pt;q=0.3\"},{\"name\":\"Sec-Ch-Ua-Platform\",\"value\":\"\\\"Windows\\\"\"},{\"name\":\"Upgrade-Insecure-Requests\",\"value\":\"1\"},{\"name\":\"Sec-Fetch-Site\",\"value\":\"none\"},{\"name\":\"Sec-Ch-Ua-Mobile\",\"value\":\"?0\"},{\"name\":\"Connection\",\"value\":\"Keep-Alive\"},{\"name\":\"Cache-Control\",\"value\":\"max-age=0\"},{\"name\":\"Sec-Ch-Ua\",\"value\":\"\\\"Chromium\\\";v=\\\"137\\\", \\\"Not A(Brand\\\";v=\\\"24\\\", \\\"Google Chrome\\\";v=\\\"137\\\"\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36\"},{\"name\":\"Accept\",\"value\":\"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"GET\",\"requestId\":\"1-698628aa-5aa33bd0197496e21c5c5cc0\",\"fragment\":\"\",\"scheme\":\"https\",\"host\":\"devlab405.click\"},\"ja3Fingerprint\":\"3adacb99ecb51ed59c4f6c4ed9a7dcaa\",\"ja4Fingerprint\":\"t13d3112h1_e8f1e7e78f70_d41ae481755e\"}",
            "ingestionTime": 1770399932446,
            "eventId": "39481237384402121288097855539895186421955169137921753088"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399914492,
            "message": "{\"timestamp\":1770399914492,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"5.75.224.239\",\"country\":\"DE\",\"headers\":[{\"name\":\"Host\",\"value\":\"devlab405.click\"},{\"name\":\"Sec-Fetch-Mode\",\"value\":\"navigate\"},{\"name\":\"Sec-Fetch-User\",\"value\":\"?1\"},{\"name\":\"Sec-Fetch-Dest\",\"value\":\"document\"},{\"name\":\"Accept-Encoding\",\"value\":\"gzip, deflate, br\"},{\"name\":\"Accept-Language\",\"value\":\"en-US,en;q=0.9,de;q=0.8,fr;q=0.7,nl;q=0.6,lb;q=0.5,es;q=0.4,pt;q=0.3\"},{\"name\":\"Sec-Ch-Ua-Platform\",\"value\":\"\\\"Windows\\\"\"},{\"name\":\"Upgrade-Insecure-Requests\",\"value\":\"1\"},{\"name\":\"Sec-Fetch-Site\",\"value\":\"none\"},{\"name\":\"Sec-Ch-Ua-Mobile\",\"value\":\"?0\"},{\"name\":\"Connection\",\"value\":\"Keep-Alive\"},{\"name\":\"Cache-Control\",\"value\":\"max-age=0\"},{\"name\":\"Sec-Ch-Ua\",\"value\":\"\\\"Chromium\\\";v=\\\"137\\\", \\\"Not A(Brand\\\";v=\\\"24\\\", \\\"Google Chrome\\\";v=\\\"137\\\"\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36\"},{\"name\":\"Accept\",\"value\":\"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7\"}],\"uri\":\"/favicon.ico\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"GET\",\"requestId\":\"1-698628aa-636d13fd357ab9675cfd3c75\",\"fragment\":\"\",\"scheme\":\"https\",\"host\":\"devlab405.click\"},\"ja3Fingerprint\":\"3adacb99ecb51ed59c4f6c4ed9a7dcaa\",\"ja4Fingerprint\":\"t13d3112h1_e8f1e7e78f70_d41ae481755e\"}",
            "ingestionTime": 1770399929777,
            "eventId": "39481237392586494775958594229612160606425411984531914752"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399916362,
            "message": "{\"timestamp\":1770399916362,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"HEAD\",\"requestId\":\"1-698628ac-04d2087e037de5e831b25870\",\"fragment\":\"\",\"scheme\":\"http\",\"host\":\"app.devlab405.click\"}}",
            "ingestionTime": 1770399928791,
            "eventId": "39481237434288888297210859503091638206249722629099683840"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399918072,
            "message": "{\"timestamp\":1770399918072,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"},{\"name\":\"Referer\",\"value\":\"http://app.devlab405.click\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"HEAD\",\"requestId\":\"1-698628ae-26d302c5133553f925003738\",\"fragment\":\"\",\"scheme\":\"https\",\"host\":\"app.devlab405.click\"},\"ja3Fingerprint\":\"20b279993ae2e137e62b9647c6d768fb\",\"ja4Fingerprint\":\"t13d131100_f57a46bbacb6_ab7e3b40a677\"}",
            "ingestionTime": 1770399928299,
            "eventId": "39481237472423162586698225074523364844660176036117544960"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399918542,
            "message": "{\"timestamp\":1770399918542,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"},{\"name\":\"Range\",\"value\":\"bytes=0-2048\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"GET\",\"requestId\":\"1-698628ae-63f9c6d87768bc9d50448f60\",\"fragment\":\"\",\"scheme\":\"http\",\"host\":\"app.devlab405.click\"}}",
            "ingestionTime": 1770399934009,
            "eventId": "39481237482904512830007617957947928167981489709951811584"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399918974,
            "message": "{\"timestamp\":1770399918974,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"},{\"name\":\"Range\",\"value\":\"bytes=0-2048\"},{\"name\":\"Referer\",\"value\":\"http://app.devlab405.click\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"GET\",\"requestId\":\"1-698628ae-4b81b2b76e0e922504043922\",\"fragment\":\"\",\"scheme\":\"https\",\"host\":\"app.devlab405.click\"},\"ja3Fingerprint\":\"20b279993ae2e137e62b9647c6d768fb\",\"ja4Fingerprint\":\"t13d131100_f57a46bbacb6_ab7e3b40a677\"}",
            "ingestionTime": 1770399937152,
            "eventId": "39481237492538434755772847158891081859132046759478755328"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399919589,
            "message": "{\"timestamp\":1770399919589,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"}],\"uri\":\"/_next\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"HEAD\",\"requestId\":\"1-698628af-66d1d09e012e13475275bf83\",\"fragment\":\"\",\"scheme\":\"http\",\"host\":\"app.devlab405.click\"}}",
            "ingestionTime": 1770399936174,
            "eventId": "39481237506253393052869180389753235075290074344122155008"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399920109,
            "message": "{\"timestamp\":1770399920109,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"},{\"name\":\"Referer\",\"value\":\"http://app.devlab405.click/_next\"}],\"uri\":\"/_next\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"HEAD\",\"requestId\":\"1-698628b0-669a754a7337fed214592d76\",\"fragment\":\"\",\"scheme\":\"https\",\"host\":\"app.devlab405.click\"},\"ja3Fingerprint\":\"20b279993ae2e137e62b9647c6d768fb\",\"ja4Fingerprint\":\"t13d131100_f57a46bbacb6_ab7e3b40a677\"}",
            "ingestionTime": 1770399928902,
            "eventId": "39481237517849780556105104414560583658486559283794083840"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399931880,
            "message": "{\"timestamp\":1770399931880,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"HEAD\",\"requestId\":\"1-698628bb-556eb9da7a6ede8907922bd8\",\"fragment\":\"\",\"scheme\":\"http\",\"host\":\"app.devlab405.click\"}}",
            "ingestionTime": 1770399946929,
            "eventId": "39481237780351852288009069435370845790174203946633527296"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399933518,
            "message": "{\"timestamp\":1770399933518,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"},{\"name\":\"Referer\",\"value\":\"http://app.devlab405.click\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"HEAD\",\"requestId\":\"1-698628bd-0699fb853a6ccf540aa5177d\",\"fragment\":\"\",\"scheme\":\"https\",\"host\":\"app.devlab405.click\"},\"ja3Fingerprint\":\"20b279993ae2e137e62b9647c6d768fb\",\"ja4Fingerprint\":\"t13d131100_f57a46bbacb6_ab7e3b40a677\"}",
            "ingestionTime": 1770399945557,
            "eventId": "39481237816880472923202230139547752577252836774112264192"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399934087,
            "message": "{\"timestamp\":1770399934087,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"},{\"name\":\"Range\",\"value\":\"bytes=0-2048\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"GET\",\"requestId\":\"1-698628be-4c2d0231212b952710cccae9\",\"fragment\":\"\",\"scheme\":\"http\",\"host\":\"app.devlab405.click\"}}",
            "ingestionTime": 1770399944653,
            "eventId": "39481237829569596941166154705988266677857434316659163136"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399934467,
            "message": "{\"timestamp\":1770399934467,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"},{\"name\":\"Range\",\"value\":\"bytes=0-2048\"},{\"name\":\"Referer\",\"value\":\"http://app.devlab405.click\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"GET\",\"requestId\":\"1-698628be-50fb15431cbd73981ba0a21c\",\"fragment\":\"\",\"scheme\":\"https\",\"host\":\"app.devlab405.click\"},\"ja3Fingerprint\":\"20b279993ae2e137e62b9647c6d768fb\",\"ja4Fingerprint\":\"t13d131100_f57a46bbacb6_ab7e3b40a677\"}",
            "ingestionTime": 1770399946543,
            "eventId": "39481237838043880116607791502057053888287113957996167168"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399935092,
            "message": "{\"timestamp\":1770399935092,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"}],\"uri\":\"/_next\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"HEAD\",\"requestId\":\"1-698628bf-1ebef39a3db5c5712cb1401b\",\"fragment\":\"\",\"scheme\":\"http\",\"host\":\"app.devlab405.click\"}}",
            "ingestionTime": 1770399951772,
            "eventId": "39481237851981845865689430971838014776368528742993821696"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399935453,
            "message": "{\"timestamp\":1770399935453,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"},{\"name\":\"Referer\",\"value\":\"http://app.devlab405.click/_next\"}],\"uri\":\"/_next\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"HEAD\",\"requestId\":\"1-698628bf-34347ffa2a777a5840046586\",\"fragment\":\"\",\"scheme\":\"https\",\"host\":\"app.devlab405.click\"},\"ja3Fingerprint\":\"20b279993ae2e137e62b9647c6d768fb\",\"ja4Fingerprint\":\"t13d131100_f57a46bbacb6_ab7e3b40a677\"}",
            "ingestionTime": 1770399950963,
            "eventId": "39481237860032414882358985924954536030777458444966690816"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399940160,
            "message": "{\"timestamp\":1770399940160,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"HEAD\",\"requestId\":\"1-698628c4-36f07c781262d9ec781238ec\",\"fragment\":\"\",\"scheme\":\"http\",\"host\":\"app.devlab405.click\"}}",
            "ingestionTime": 1770399957670,
            "eventId": "39481237965002022531842629060271567366910900704823934976"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399941806,
            "message": "{\"timestamp\":1770399941806,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"},{\"name\":\"Referer\",\"value\":\"http://app.devlab405.click\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"HEAD\",\"requestId\":\"1-698628c5-3e5057e66e673807750f34f5\",\"fragment\":\"\",\"scheme\":\"https\",\"host\":\"app.devlab405.click\"},\"ja3Fingerprint\":\"20b279993ae2e137e62b9647c6d768fb\",\"ja4Fingerprint\":\"t13d131100_f57a46bbacb6_ab7e3b40a677\"}",
            "ingestionTime": 1770399951816,
            "eventId": "39481238001709049128624034744162097543313428852179730432"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399942317,
            "message": "{\"timestamp\":1770399942317,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"},{\"name\":\"Range\",\"value\":\"bytes=0-2048\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"GET\",\"requestId\":\"1-698628c6-3920b0d627aca6cb1f1118f7\",\"fragment\":\"\",\"scheme\":\"http\",\"host\":\"app.devlab405.click\"}}",
            "ingestionTime": 1770399957049,
            "eventId": "39481238013104729925073183175813544179505013828751065088"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399942694,
            "message": "{\"timestamp\":1770399942694,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"},{\"name\":\"Range\",\"value\":\"bytes=0-2048\"},{\"name\":\"Referer\",\"value\":\"http://app.devlab405.click\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"GET\",\"requestId\":\"1-698628c6-31e2b09e3393e0a732396d26\",\"fragment\":\"\",\"scheme\":\"https\",\"host\":\"app.devlab405.click\"},\"ja3Fingerprint\":\"20b279993ae2e137e62b9647c6d768fb\",\"ja4Fingerprint\":\"t13d131100_f57a46bbacb6_ab7e3b40a677\"}",
            "ingestionTime": 1770399957428,
            "eventId": "39481238021512110864919228100630550845083963138297692160"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770399943299,
            "message": "{\"timestamp\":1770399943299,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"176.65.148.161\",\"country\":\"NL\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.devlab405.click\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)\"},{\"name\":\"Accept\",\"value\":\"*/*\"}],\"uri\":\"/_next\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"HEAD\",\"requestId\":\"1-698628c7-5eb14f961a3778730ebc3503\",\"fragment\":\"\",\"scheme\":\"http\",\"host\":\"app.devlab405.click\"}}",
            "ingestionTime": 1770399955805,
            "eventId": "39481238035004061710030255099297539385231886987105009664"
        }
    ],
    "searchedLogStreams": [],
    "nextToken": "Bxkq6kVGFtq2y_MoigeqscPOdhXVbhiVtLoAmXb5jCrUzteJFrwmne-SZ95Q1Ws8GEUI-NXSrK7GTFbrmSJSKZmS8Rd6mT1gEXq5U43VDRB--wd4N6iZMfnYl0u2_3G34oOw9RUf3gpzmbYfbY372BpMTKQOqZv2OyRi_8NKCpSiBV-ppIvSkcSi0JQ9_5UAADd4cuzU_JVMir5pW0nh0q8VDBgH-Lj8MQ0pEnF-B1aQMjoLMizAiMQbdaAfuxQycUwqonBYe5YGFuR4iQjB_eokL1L--df9uhoGsQxtthNubFId3n76MRSQVYgvKtRd9pAO-1ZojfO0k0D4tWpjZQ"
}


## Learned to use filter for only last 10 minutes to avoid too much data and to get more relevant data. Also learned to use nextToken to paginate through results if needed.

START_MS=$(( ($(date +%s) - 600) * 1000 ))# Allows you to filter log events from the last 10 minutes (600 seconds) by calculating the start time in milliseconds.
```
aws logs filter-log-events \
  --region "$REGION" \
  --log-group-name "$WAF_LOG_GROUP" \
  --start-time "$START_MS" \
  --max-items 50 \
  --output json 
```
  $ aws logs filter-log-events \
>   --region "$REGION" \
>   --log-group-name "$WAF_LOG_GROUP" \
>   --start-time "$START_MS" \
>   --max-items 50 \
>   --output json 
{
    "events": [
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770409400615,
            "message": "{\"timestamp\":1770409400615,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"178.24.86.77\",\"country\":\"DE\",\"headers\":[{\"name\":\"host\",\"value\":\"app.devlab405.click\"},{\"name\":\"user-agent\",\"value\":\"curl/8.7.1\"},{\"name\":\"accept\",\"value\":\"*/*\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/2.0\",\"httpMethod\":\"HEAD\",\"requestId\":\"1-69864db8-32153f8f18f7fd0c65a66701\",\"fragment\":\"\",\"scheme\":\"https\",\"host\":\"app.devlab405.click\"},\"ja3Fingerprint\":\"375c6162a492dfbf2795909110ce8424\",\"ja4Fingerprint\":\"t13d4907h2_0d8feac7bc37_7395dae3b2f3\"}",
            "ingestionTime": 1770409426838,
            "eventId": "39481448940198439696868992965086972616175189906510774272"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770409434441,
            "message": "{\"timestamp\":1770409434441,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"167.179.119.118\",\"country\":\"JP\",\"headers\":[{\"name\":\"Host\",\"value\":\"ws.bitget.com\"},{\"name\":\"User-Agent\",\"value\":\"Go-http-client/1.1\"},{\"name\":\"Connection\",\"value\":\"Upgrade\"},{\"name\":\"Sec-WebSocket-Key\",\"value\":\"M9SqCGQFzA4IkfIYw+mmtA==\"},{\"name\":\"Sec-WebSocket-Version\",\"value\":\"13\"},{\"name\":\"Upgrade\",\"value\":\"websocket\"}],\"uri\":\"/mix/v1/stream\",\"args\":\"compress=true\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"GET\",\"requestId\":\"1-69864dda-55d5e8ab680684bb72e613b4\",\"fragment\":\"\",\"scheme\":\"https\",\"host\":\"ws.bitget.com\"},\"ja3Fingerprint\":\"1be8360b66649edee1de25f81d98ec27\",\"ja4Fingerprint\":\"t13d191000_9dc949149365_e7c285222651\"}",
            "ingestionTime": 1770409445636,
            "eventId": "39481449694543446782365851373399604673097811963982905344"
        },
        {
            "logStreamName": "ap-northeast-1_lab-1c-waf_0",
            "timestamp": 1770409594818,
            "message": "{\"timestamp\":1770409594818,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/3b812466-113f-4cd7-9c17-0523752ab048\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"261519058382-app/lab-1c-alb/8ca037ef5ddd6217\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"204.76.203.206\",\"country\":\"NL\",\"headers\":[{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0\"},{\"name\":\"Host\",\"value\":\"54.64.241.248\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"GET\",\"requestId\":\"1-69864e7a-23ddee1830ab9cd6437c0d24\",\"fragment\":\"\",\"scheme\":\"http\",\"host\":\"54.64.241.248\"}}",
            "ingestionTime": 1770409617550,
            "eventId": "39481453271070059487111599151304425803257313348328423424"
        }
    ],
    "searchedLogStreams": []
}

## If S3 is the destination for WAF logs, you can also check the S3 bucket for the logs. I used CloudWatch so this is just for future reference if you want to use S3 for logging. You can use the AWS CLI to list the objects in the S3 bucket and then download the logs for analysis.

### List objects in the S3 bucket (replace with your bucket name and prefix if needed)

```
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws s3 ls "s3://aws-waf-logs--${ACCOUNT_ID}/" --recursive | head \
  | tee deliverables/bonus_e_C2_s3_head.txt
```

## If Firehose is the destination for WAF logs, you can check the Firehose delivery stream for the logs. You can use the AWS CLI to describe the delivery stream and check the status of the delivery stream and the destination.

### Describe the Firehose delivery stream (replace with your delivery stream name)

```
FIREHOSE_STREAM_NAME="aws-waf-logs--firehose01"

aws firehose describe-delivery-stream \
  --region "$REGION" \
  --delivery-stream-name "$FIREHOSE_STREAM_NAME" \
  --query "DeliveryStreamDescription.DeliveryStreamStatus" \
  --output text | tee deliverables/bonus_e_C3_firehose_status.txt
```

## For firehouse you want to confirm that the data is being delivered to the destination (e.g., S3, Redshift, Elasticsearch) and check the logs in the destination for analysis. You can also check the metrics for the Firehose delivery stream to see if there are any issues with data delivery.

[NOTE] For the sake of this lab, I have not set up a Firehose delivery stream, so I cannot provide specific commands for checking the logs in the destination. However, you can refer to the AWS documentation for Firehose to learn how to check the logs in the destination and monitor the delivery stream metrics. I did find a useful command to check that the data is being delivered to the S3 bucket if you have set up Firehose to deliver to S3:

```
FIREHOSE_DEST_BUCKET="<firehose_dest_bucket>"
aws s3 ls "s3://${FIREHOSE_DEST_BUCKET}/" --recursive | head
```

[CAUTION] Remember to replace `<firehose_dest_bucket>` with the actual name of your S3 bucket that is the destination for the Firehose delivery stream. This command will list the objects in the S3 bucket, allowing you to confirm that the data is being delivered to the bucket. When using the "head" command, be cautious as it will only show the first few entries. If you have a large number of logs, you may want to use other commands to filter or search for specific logs in the S3 bucket.

