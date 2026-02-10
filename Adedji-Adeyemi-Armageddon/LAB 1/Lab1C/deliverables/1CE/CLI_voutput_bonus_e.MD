Student verification (CLI)

Confirm WAF logging is enabled (authoritative)

aws wafv2 get-logging-configuration \
--resource-arn arn:aws:wafv2:ap-northeast-1:620812304994:regional/webacl/armageddon-class-vii-waf01/bc4383ea-9bc9-4ed8-963f-ce2d8b7d454c

aws logs describe-log-streams \  
--log-group-name aws-waf-logs-armageddon-class-vii-webacl01 \
--order-by LastEventTime --descending

aws logs filter-log-events \
--log-group-name aws-waf-logs-armageddon-class-vii-webacl01 \
--max-items 20
