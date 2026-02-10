Verification commands (CLI) for Bonus-B

1. ALB exists and is active

aws elbv2 describe-load-balancers
--names chewbacca-alb01
--query "LoadBalancers[0].State.Code"

    {
    "LoadBalancers": [
        {
            "LoadBalancerArn": "arn:aws:elasticloadbalancing:ap-northeast-1:420228061920:loadbalancer/app/armageddon-class-vii-alb01/1f44bd3bf550842b",
            "DNSName": "armageddon-class-vii-alb01-1561408838.ap-northeast-1.elb.amazonaws.com",
            "CanonicalHostedZoneId": "Z14GRHDCWA56QT",
            "CreatedTime": "2026-02-09T23:00:05.869000+00:00",
            "LoadBalancerName": "armageddon-class-vii-alb01",
            "Scheme": "internet-facing",
            "VpcId": "vpc-09e7e6cc5ac255b7c",
            "State": {
                "Code": "active"
            },
            "Type": "application",
            "AvailabilityZones": [
                {
                    "ZoneName": "ap-northeast-1a",
                    "SubnetId": "subnet-037452bc845b32126",
                    "LoadBalancerAddresses": []
                },
                {
                    "ZoneName": "ap-northeast-1c",
                    "SubnetId": "subnet-0b9295da76565d069",
                    "LoadBalancerAddresses": []
                }
            ],
            "SecurityGroups": [
                "sg-0fe946c8fb040c49e"
            ],
            "IpAddressType": "ipv4",
            "EnablePrefixForIpv6SourceNat": "off"
        }
    ]
}





2. HTTPS listener exists on 443

aws elbv2 describe-listeners \
--load-balancer-arn arn:aws:elasticloadbalancing:ap-northeast-1:420228061920:loadbalancer/app/armageddon-class-vii-alb01/1f44bd3bf550842b \
--query "Listeners[].Port"

[
    80,
    443
]

3. Target is healthy

aws elbv2 describe-target-health
--target-group-arn arn:aws:elasticloadbalancing:ap-northeast-1:420228061920:targetgroup/armageddon-class-vii-tg01/6d4dc0051d12114b

{
    "TargetHealthDescriptions": [
        {
            "Target": {
                "Id": "i-07b29863a3989bb58",
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

4. WAF attached

aws wafv2 get-web-acl-for-resource
--resource-arn arn:aws:elasticloadbalancing:ap-northeast-1:420228061920:loadbalancer/app/armageddon-class-vii-alb01/1f44bd3bf550842b

{
    "WebACL": {
        "Name": "armageddon-class-vii-waf01",
        "Id": "baf4c31b-d595-495c-adaf-4c8238d629a4",
        "ARN": "arn:aws:wafv2:ap-northeast-1:420228061920:regional/webacl/armageddon-class-vii-waf01/baf4c31b-d595-495c-adaf-4c8238d629a4",
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


5. Alarm created (ALB 5xx)

aws cloudwatch describe-alarms

{
    "MetricAlarms": [
    "MetricAlarms": [
        {
            "AlarmName": "armageddon-class-vii-alb-5xx-alarm01",
            "AlarmArn": "arn:aws:cloudwatch:ap-northeast-1:420228061920:alarm:armageddon-class-vii-alb-5xx-alarm01",
            "AlarmConfigurationUpdatedTimestamp": "2026-02-09T23:02:48.290000+00:00",
            "ActionsEnabled": true,
            "OKActions": [],
            "AlarmActions": [
                "arn:aws:sns:ap-northeast-1:420228061920:armageddon-class-vii-db-incidents"
            ],
            "InsufficientDataActions": [],
            "StateValue": "INSUFFICIENT_DATA",
            "StateReason": "Unchecked: Initial alarm creation",
            "StateUpdatedTimestamp": "2026-02-09T23:02:48.290000+00:00",
            "MetricName": "HTTPCode_ELB_5XX_Count",
            "Namespace": "AWS/ApplicationELB",
            "Statistic": "Sum",
            "Dimensions": [
                {
                    "Name": "LoadBalancer",
                    "Value": "app/armageddon-class-vii-alb01/1f44bd3bf550842b"
                }
            ],
            "Period": 300,
            "EvaluationPeriods": 1,
            "Threshold": 10.0,
            "ComparisonOperator": "GreaterThanOrEqualToThreshold",
            "TreatMissingData": "missing",
            "StateTransitionedTimestamp": "2026-02-09T23:02:48.290000+00:00"
        },
        {
            "AlarmName": "armageddon-class-vii-db-connection-failure",
            "AlarmArn": "arn:aws:cloudwatch:ap-northeast-1:420228061920:alarm:armageddon-class-vii-db-connection-failure",
            "AlarmConfigurationUpdatedTimestamp": "2026-02-09T18:20:57.950000+00:00",
            "ActionsEnabled": true,
            "OKActions": [],
            "AlarmActions": [
                "arn:aws:sns:ap-northeast-1:420228061920:armageddon-class-vii-db-incidents"
            ],
            "InsufficientDataActions": [],
            "StateValue": "INSUFFICIENT_DATA",
            "StateReason": "Insufficient Data: 1 datapoint was unknown.",
            "StateReasonData": "{\"version\":\"1.0\",\"queryDate\":\"2026-02-10T01:07:39.136+0000\",\"statistic\":\"Sum\",\"period\":300,\"recentDatapoints\":[],\"threshold\":3.0,\"evaluatedDatapoints\":[{\"timestamp\":\"2026-02-10T01:02:00.000+0000\"}]}",
            "StateUpdatedTimestamp": "2026-02-10T01:07:39.138000+00:00",
            "MetricName": "DBConnectionErrors",
            "Namespace": "Lab/RDSApp",
            "Statistic": "Sum",
            "Dimensions": [],
            "Period": 300,
            "EvaluationPeriods": 1,
            "Threshold": 3.0,
            "ComparisonOperator": "GreaterThanOrEqualToThreshold",
            "TreatMissingData": "missing",
            "StateTransitionedTimestamp": "2026-02-10T01:07:39.138000+00:00"
        },
        {
            "AlarmName": "lew-alb-5xx-alarm01",
            "AlarmArn": "arn:aws:cloudwatch:ap-northeast-1:420228061920:alarm:lew-alb-5xx-alarm01",
            "AlarmConfigurationUpdatedTimestamp": "2026-02-04T01:53:01.726000+00:00",
            "ActionsEnabled": true,
            "OKActions": [],
            "AlarmActions": [
                "arn:aws:sns:ap-northeast-1:420228061920:lew-db-incidents"
            ],
            "InsufficientDataActions": [],
            "StateValue": "INSUFFICIENT_DATA",
            "StateReason": "Unchecked: Initial alarm creation",
            "StateUpdatedTimestamp": "2026-02-04T01:53:01.726000+00:00",
            "MetricName": "HTTPCode_ELB_5XX_Count",
            "Namespace": "AWS/ApplicationELB",
            "Statistic": "Sum",
            "Dimensions": [
                {
                    "Name": "LoadBalancer",
                    "Value": "app/lew-alb01/04ca415b37524772"
                }
            ],
            "Period": 300,
            "EvaluationPeriods": 1,
            "Threshold": 10.0,
            "ComparisonOperator": "GreaterThanOrEqualToThreshold",
            "TreatMissingData": "missing",
            "StateTransitionedTimestamp": "2026-02-04T01:53:01.726000+00:00"
        }
    ],
    "CompositeAlarms": []
}
Dashboard exists

aws cloudwatch list-dashboards
{
    "DashboardEntries": [
        {
            "DashboardName": "armageddon-class-vii-dashboard01",
            "DashboardArn": "arn:aws:cloudwatch::420228061920:dashboard/armageddon-class-vii-dashboard01",
            "LastModified": "2026-02-09T23:02:49+00:00",
            "Size": 700
        }
}