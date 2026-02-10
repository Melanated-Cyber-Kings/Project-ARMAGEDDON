Student verification (CLI) — DNS + Logs

1. Verify apex record exists

aws route53 list-resource-record-sets
--hosted-zone-id 
--query "ResourceRecordSets[?Name=='']"


2. Verify ALB logging is enabled

aws elbv2 describe-load-balancers \
--names lew-alb01 \
--query "LoadBalancers[0].LoadBalancerArn"

"arn:aws:elasticloadbalancing:ap-northeast-1:620812304994:loadbalancer/app/lew-alb01/5bacfef0e722326b"

aws elbv2 describe-load-balancer-attributes \
--load-balancer-arn "arn:aws:elasticloadbalancing:ap-northeast-1:620812304994:loadbalancer/app/lew-alb01/5bacfef0e722326b"
