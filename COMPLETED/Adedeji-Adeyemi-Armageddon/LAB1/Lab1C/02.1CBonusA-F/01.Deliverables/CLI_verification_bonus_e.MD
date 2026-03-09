Student verification (CLI)

1. Confirm WAF logging is enabled (authoritative)

aws wafv2 get-logging-configuration 
--resource-arn "arn:aws:wafv2:ap-northeast-1:420228061920:regional/webacl/armageddon-class-vii-waf01/4c1d085f-ef73-4294-9052-7af6620c025a"

{
    "LoggingConfiguration": {
        "ResourceArn": "arn:aws:wafv2:ap-northeast-1:420228061920:regional/webacl/armageddon-class-vii-waf01/4c1d085f-ef73-4294-9052-7af6620c025a",
        "LogDestinationConfigs": [
            "arn:aws:logs:ap-northeast-1:420228061920:log-group:aws-waf-logs-armageddon-class-vii-webacl01"
        ],
        "ManagedByFirewallManager": false,
        "LogType": "WAF_LOGS",
        "LogScope": "CUSTOMER"
    }
}

2. aws logs describe-log-streams   
--log-group-name "aws-waf-logs-armageddon-class-vii-webacl01" 
--order-by LastEventTime --descending

{{
    "logStreams": [
        {
            "logStreamName": "ap-northeast-1_armageddon-class-vii-waf01_0",
            "creationTime": 1772658128485,
            "firstEventTimestamp": 1772658117136,
            "lastEventTimestamp": 1772666029054,
            "lastIngestionTime": 1772666044741,
            "uploadSequenceToken": "49039859663985777314520551860641067976984664529735621221",
            "arn": "arn:aws:logs:ap-northeast-1:420228061920:log-group:aws-waf-logs-armageddon-class-vii-webacl01:log-stream:ap-northeast-1_armageddon-class-vii-waf01_0",
            "storedBytes": 0
        },
        {
            "logStreamName": "log_stream_created_by_aws_to_validate_log_delivery_subscriptions",
            "creationTime": 1772657737017,
            "firstEventTimestamp": 1772657737027,
            "lastEventTimestamp": 1772657737027,
            "lastIngestionTime": 1772657737037,
            "uploadSequenceToken": "49039859663974734481783057531904082647878274965721684517",
            "arn": "arn:aws:logs:ap-northeast-1:420228061920:log-group:aws-waf-logs-armageddon-class-vii-webacl01:log-stream:log_stream_created_by_aws_to_validate_log_delivery_subscriptions",
            "storedBytes": 0
        }
    ]
}

3. aws logs filter-log-events 
--log-group-name aws-waf-logs-armageddon-class-vii-webacl01 
--max-items 2

{
    "events": [
        {
            "logStreamName": "log_stream_created_by_aws_to_validate_log_delivery_subscriptions",
            "timestamp": 1772657737027,
            "message": "Permissions are set correctly to allow AWS CloudWatch Logs to write into your logs while creating a subscription.",
            "ingestionTime": 1772657737037,
            "eventId": "39531588517643030265777875590328118156439554413930610688"
        },
        {
            "logStreamName": "ap-northeast-1_armageddon-class-vii-waf01_0",
            "timestamp": 1772658117136,
            "message": "{\"timestamp\":1772658117136,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:ap-northeast-1:420228061920:regional/webacl/armageddon-class-vii-waf01/4c1d085f-ef73-4294-9052-7af6620c025a\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"420228061920-app/armageddon-class-vii-alb01/202e960cc5b39f1d\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"204.76.203.212\",\"country\":\"NL\",\"headers\":[{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.85 Safari/537.36 Edg/90.0.818.46\"},{\"name\":\"Accept-Encoding\",\"value\":\"gzip, deflate\"},{\"name\":\"Accept\",\"value\":\"*/*\"},{\"name\":\"Connection\",\"value\":\"keep-alive\"},{\"name\":\"X-Requested-With\",\"value\":\"XMLHttpRequest\"},{\"name\":\"Content-Type\",\"value\":\"application/x-www-form-urlencoded; charset=UTF-8\"},{\"name\":\"Accept-Encoding\",\"value\":\"gzip, deflate\"},{\"name\":\"Accept-Language\",\"value\":\"en US,en;q=0.9,sv;q=0.8\"},{\"name\":\"Host\",\"value\":\"176.32.72.129\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"GET\",\"requestId\":\"1-69a89dc5-0c537a7e242a01b814afd251\",\"fragment\":\"\",\"scheme\":\"http\",\"host\":\"176.32.72.129\"}}",
            "ingestionTime": 1772658128588,
            "eventId": "39531596994356986934054507769684106738067546321212669952"
        }
    ],
    "searchedLogStreams": [],
    "NextToken": "eyJuZXh0VG9rZW4iOiBudWxsLCAiYm90b190cnVuY2F0ZV9hbW91bnQiOiAyfQ=="
}
