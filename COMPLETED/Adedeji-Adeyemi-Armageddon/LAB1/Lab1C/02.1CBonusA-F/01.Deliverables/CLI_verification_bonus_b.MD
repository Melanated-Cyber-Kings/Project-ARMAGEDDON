1) Verification commands (CLI) for Bonus-B

ALB exists and is active

aws elbv2 describe-load-balancers 
--names "armageddon-class-vii-alb01" 
--query "LoadBalancers[0].State.Code"

{
    "LoadBalancers": [
        {
            "LoadBalancerArn": "arn:aws:elasticloadbalancing:ap-northeast-1:420228061920:loadbalancer/app/armageddon-class-vii-alb01/202e960cc5b39f1d",
            "DNSName": "armageddon-class-vii-alb01-866112400.ap-northeast-1.elb.amazonaws.com",
            "CanonicalHostedZoneId": "Z14GRHDCWA56QT",
            "CreatedTime": "2026-03-04T20:56:12.002000+00:00",
            "LoadBalancerName": "armageddon-class-vii-alb01",
            "Scheme": "internet-facing",
            "VpcId": "vpc-07e52e6f899ae86ca",
            "State": {
                "Code": "active"
            },
            "Type": "application",
            "AvailabilityZones": [
                {
                    "ZoneName": "ap-northeast-1a",
                    "SubnetId": "subnet-01a59fcfe8c0a7c25",
                    "LoadBalancerAddresses": []
                },
                {
                    "ZoneName": "ap-northeast-1c",
                    "SubnetId": "subnet-0d3e35b3d569b63f2",
                    "LoadBalancerAddresses": []
                }
            ],
            "SecurityGroups": [
                "sg-05f7a2c537675ae46"
            ],
            "IpAddressType": "ipv4",
            "EnablePrefixForIpv6SourceNat": "off"
        }
    ]
}

"Active"

2) HTTPS listener exists on 443

aws elbv2 describe-listeners 
--load-balancer-arn "arn:aws:elasticloadbalancing:ap-northeast-1:420228061920:loadbalancer/app/armageddon-class-vii-alb01/202e960cc5b39f1d"
--query "Listeners[].Port"

[
    443,
    80
]

3) Target is healthy

aws elbv2 describe-target-health 
--target-group-arn "arn:aws:elasticloadbalancing:ap-northeast-1:420228061920:targetgroup/armageddon-class-vii-tg01/5d39017416fcd485"

{
    "TargetHealthDescriptions": [
        {
            "Target": {
                "Id": "i-042b0c597f59025ac",
                "Port": 80
            },
            "HealthCheckPort": "80",
            "TargetHealth": {
                "State": "healthy"
            },
            "AdministrativeOverride": {
                "State": "no_override",
                "Reason": "AdministrativeOverride.NoOverride",
                "Description": "No override is currently active on target"
            }
        }
    ]
}


4) WAF attached

aws wafv2 get-web-acl-for-resource 
--resource-arn "arn:aws:elasticloadbalancing:ap-northeast-1:420228061920:loadbalancer/app/armageddon-class-vii-alb01/202e960cc5b39f1d"

{
    "WebACL": {
        "Name": "armageddon-class-vii-waf01",
        "Id": "4c1d085f-ef73-4294-9052-7af6620c025a",
        "ARN": "arn:aws:wafv2:ap-northeast-1:420228061920:regional/webacl/armageddon-class-vii-waf01/4c1d085f-ef73-4294-9052-7af6620c025a",
        "DefaultAction": {
            "Allow": {}
        },
        "Description": "",
        "Rules": [
            {
                "Name": "AWSManagedRulesCommonRuleSet",
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
                    "MetricName": "armageddon-class-vii-waf-common"
                }
            }
        ],
        "VisibilityConfig": {
            "SampledRequestsEnabled": true,
            "CloudWatchMetricsEnabled": true,
            "MetricName": "armageddon-class-vii-waf01"
        },
        "Capacity": 700,
        "ManagedByFirewallManager": false,
        "LabelNamespace": "awswaf:420228061920:webacl:armageddon-class-vii-waf01:",
        "RetrofittedByFirewallManager": false,
        "OnSourceDDoSProtectionConfig": {
            "ALBLowReputationMode": "ACTIVE_UNDER_DDOS"
        }
    }
}


5) Alarm created (ALB 5xx)

aws cloudwatch describe-alarms 
--alarm-name-prefix armageddon-class-vii-alb-5xx

{
    "MetricAlarms": [
        {
            "AlarmName": "armageddon-class-vii-alb-5xx-alarm01",
            "AlarmArn": "arn:aws:cloudwatch:ap-northeast-1:420228061920:alarm:armageddon-class-vii-alb-5xx-alarm01",
            "AlarmConfigurationUpdatedTimestamp": "2026-03-04T20:58:33.481000+00:00",
            "ActionsEnabled": true,
            "OKActions": [],
            "AlarmActions": [
                "arn:aws:sns:ap-northeast-1:420228061920:armageddon-class-vii-db-incidents"
            ],
            "InsufficientDataActions": [],
            "StateValue": "INSUFFICIENT_DATA",
            "StateReason": "Insufficient Data: 1 datapoint was unknown.",
            "StateReasonData": "{\"version\":\"1.0\",\"queryDate\":\"2026-03-04T21:56:08.423+0000\",\"statistic\":\"Sum\",\"period\":300,\"recentDatapoints\":[],\"threshold\":10.0,\"evaluatedDatapoints\":[{\"timestamp\":\"2026-03-04T21:49:00.000+0000\"}]}",
            "StateUpdatedTimestamp": "2026-03-04T21:56:08.424000+00:00",
            "MetricName": "HTTPCode_ELB_5XX_Count",
            "Namespace": "AWS/ApplicationELB",
            "Statistic": "Sum",
            "Dimensions": [
                {
                    "Name": "LoadBalancer",
                    "Value": "app/armageddon-class-vii-alb01/202e960cc5b39f1d"
                }
            ],
            "Period": 300,
            "EvaluationPeriods": 1,
            "Threshold": 10.0,
            "ComparisonOperator": "GreaterThanOrEqualToThreshold",
            "TreatMissingData": "missing",
            "StateTransitionedTimestamp": "2026-03-04T21:56:08.424000+00:00"
        }
    ],
    "CompositeAlarms": []
}


6) Dashboard exists

aws cloudwatch list-dashboards 
--dashboard-name-prefix armageddon-class-vii

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

