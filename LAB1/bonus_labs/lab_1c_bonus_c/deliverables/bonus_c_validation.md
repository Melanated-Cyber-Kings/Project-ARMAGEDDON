# Bonus C — Validation Report
Generated (UTC): `2026-02-05 01:27:32Z`
Region: `ap-northeast-1`

## Terraform Outputs (root)

| Component | Status | Value |
|---|---:|---|
| **FQDN (via DNS lookup)** | 🟢 | `app.devlab405.click` |
| **ALB Name** | 🟢 | `lab-1c-alb` |
| **ALB ARN** | 🟢 | `arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:loadbalancer/app/lab-1c-alb/5e6e0819de4af97e` |
| **Target Group ARN** | 🟢 | `arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:targetgroup/lab-1c-tg/365123ffa7cdbad6` |
| **ACM Cert ARN** | 🟢 | `arn:aws:acm:ap-northeast-1:261519058382:certificate/b43e8846-4e1b-404a-8175-379ed8998e31` |
| **WAF ARN (tf output)** | 🟢 | `arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/05991ed9-d8a9-4516-b98a-0bfd1dc25e0f` |
| **WAF ARN (attached)** | 🟢 | `arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/05991ed9-d8a9-4516-b98a-0bfd1dc25e0f` |
| **SNS Topic ARN** | 🟢 | `arn:aws:sns:ap-northeast-1:261519058382:lab-db-incidents` |
| **ALB 5xx Alarm Name** | 🟢 | `lab-1c-alb-5xx` |
| **Dashboard Name** | 🟢 | `lab-1c-alb-dashboard` |
| **Route53 Zone ID (resolved)** | 🟢 | `Z103851437PNELROEQ0AM` |

## DNS Resolution Evidence

| Check | Status | Command | Result |
|---|---:|---|---|
| **FQDN A record** | 🟢 | `dig app.devlab405.click +short` | `43.207.14.190 3.115.177.117 ` |

## ALB Status
- Scheme: `internet-facing` (expected: internet-facing)
- State: `active` (expected: active)
- DNS: `lab-1c-alb-991397764.ap-northeast-1.elb.amazonaws.com`

## ALB Listeners
```
---------------------------------------------------------------------------------------------------------------------------------------------
|                                                             DescribeListeners                                                             |
+-------------------------------------------------------------------------------------------------------------------------------------------+
||                                                                Listeners                                                                ||
|+-----------------+-----------------------------------------------------------------------------------------------------------------------+|
||  ListenerArn    |  arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:listener/app/lab-1c-alb/5e6e0819de4af97e/925729c7b2de4d10   ||
||  LoadBalancerArn|  arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:loadbalancer/app/lab-1c-alb/5e6e0819de4af97e                ||
||  Port           |  443                                                                                                                  ||
||  Protocol       |  HTTPS                                                                                                                ||
||  SslPolicy      |  ELBSecurityPolicy-TLS13-1-2-2021-06                                                                                  ||
|+-----------------+-----------------------------------------------------------------------------------------------------------------------+|
|||                                                             Certificates                                                              |||
||+--------------------+------------------------------------------------------------------------------------------------------------------+||
|||  CertificateArn    |  arn:aws:acm:ap-northeast-1:261519058382:certificate/b43e8846-4e1b-404a-8175-379ed8998e31                        |||
||+--------------------+------------------------------------------------------------------------------------------------------------------+||
|||                                                            DefaultActions                                                             |||
||+-------------------+-------------------------------------------------------------------------------------------------------------------+||
|||  Order            |  1                                                                                                                |||
|||  TargetGroupArn   |  arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:targetgroup/lab-1c-tg/365123ffa7cdbad6                  |||
|||  Type             |  forward                                                                                                          |||
||+-------------------+-------------------------------------------------------------------------------------------------------------------+||
||||                                                            ForwardConfig                                                            ||||
|||+-------------------------------------------------------------------------------------------------------------------------------------+|||
|||||                                                    TargetGroupStickinessConfig                                                    |||||
||||+-----------------------------------------------------------------------+-----------------------------------------------------------+||||
|||||  Enabled                                                              |  False                                                    |||||
||||+-----------------------------------------------------------------------+-----------------------------------------------------------+||||
|||||                                                           TargetGroups                                                            |||||
||||+------------------+----------------------------------------------------------------------------------------------------------------+||||
|||||  TargetGroupArn  |  arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:targetgroup/lab-1c-tg/365123ffa7cdbad6               |||||
|||||  Weight          |  1                                                                                                             |||||
||||+------------------+----------------------------------------------------------------------------------------------------------------+||||
|||                                                         MutualAuthentication                                                          |||
||+-----------------------------------------------------------------------+---------------------------------------------------------------+||
|||  Mode                                                                 |  off                                                          |||
||+-----------------------------------------------------------------------+---------------------------------------------------------------+||
||                                                                Listeners                                                                ||
|+-----------------+-----------------------------------------------------------------------------------------------------------------------+|
||  ListenerArn    |  arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:listener/app/lab-1c-alb/5e6e0819de4af97e/f7a03ae85b41392c   ||
||  LoadBalancerArn|  arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:loadbalancer/app/lab-1c-alb/5e6e0819de4af97e                ||
||  Port           |  80                                                                                                                   ||
||  Protocol       |  HTTP                                                                                                                 ||
||  SslPolicy      |                                                                                                                       ||
|+-----------------+-----------------------------------------------------------------------------------------------------------------------+|
|||                                                            DefaultActions                                                             |||
||+---------------------------------------------------------+-----------------------------------------------------------------------------+||
|||  Order                                                  |  1                                                                          |||
|||  Type                                                   |  redirect                                                                   |||
||+---------------------------------------------------------+-----------------------------------------------------------------------------+||
||||                                                           RedirectConfig                                                            ||||
|||+-----------------------------------------------------------------------+-------------------------------------------------------------+|||
||||  Host                                                                 |  #{host}                                                    ||||
||||  Path                                                                 |  /#{path}                                                   ||||
||||  Port                                                                 |  443                                                        ||||
||||  Protocol                                                             |  HTTPS                                                      ||||
||||  Query                                                                |  #{query}                                                   ||||
||||  StatusCode                                                           |  HTTP_301                                                   ||||
|||+-----------------------------------------------------------------------+-------------------------------------------------------------+|||
```

## Target Health
```
------------------------------------------------------------------
|                      DescribeTargetHealth                      |
+----------------------------------------------------------------+
||                   TargetHealthDescriptions                   ||
|+-----------------------------------------------+--------------+|
||  HealthCheckPort                              |  80          ||
|+-----------------------------------------------+--------------+|
|||                   AdministrativeOverride                   |||
||+-------------+----------------------------------------------+||
|||  Description|  No override is currently active on target   |||
|||  Reason     |  AdministrativeOverride.NoOverride           |||
|||  State      |  no_override                                 |||
||+-------------+----------------------------------------------+||
|||                           Target                           |||
||+--------------+---------------------------------------------+||
|||  Id          |  i-0e3925bebc447fd12                        |||
|||  Port        |  80                                         |||
||+--------------+---------------------------------------------+||
|||                        TargetHealth                        |||
||+--------------------------+---------------------------------+||
|||  State                   |  healthy                        |||
||+--------------------------+---------------------------------+||
```

## ACM Certificate
- Status: `ISSUED` (expected: ISSUED)
- DomainName: `app.devlab405.click`
- NotAfter: `2027-03-06T00:59:59+01:00`

### Validation Options (records ACM expects)
```
---------------------------------------------------------------------------------
|                              DescribeCertificate                              |
+--------+----------------------------------------------------------------------+
|  Domain|  app.devlab405.click                                                 |
|  Name  |  _f4fe8d69a8756f70c3659e242eebe39a.app.devlab405.click.              |
|  Type  |  CNAME                                                               |
|  Value |  _958f675658fb59e44aded32d4a520594.jkddzztszm.acm-validations.aws.   |
+--------+----------------------------------------------------------------------+
```

## WAF Attached + Logging
- Attached: 🟢 `lab-1c-waf`
- WebACL ARN: `arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/05991ed9-d8a9-4516-b98a-0bfd1dc25e0f`
- Logging Destination: `arn:aws:logs:ap-northeast-1:261519058382:log-group:aws-waf-logs-lab-1c-webacl`

### WAF Logging Configuration (raw JSON)
```
{
    "LoggingConfiguration": {
        "ResourceArn": "arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/05991ed9-d8a9-4516-b98a-0bfd1dc25e0f",
        "LogDestinationConfigs": [
            "arn:aws:logs:ap-northeast-1:261519058382:log-group:aws-waf-logs-lab-1c-webacl"
        ],
        "ManagedByFirewallManager": false,
        "LogType": "WAF_LOGS",
        "LogScope": "CUSTOMER"
    }
}
```

### WAF CloudWatch Log Group Validation

| Check | Status | Value |
|---|---:|---|
| **Log group name (derived)** | 🟢 | `aws-waf-logs-lab-1c-webacl` |
| **Log group exists** | 🟢 | `yes` |
| **Log group ARN** | 🟢 | `arn:aws:logs:ap-northeast-1:261519058382:log-group:aws-waf-logs-lab-1c-webacl:*` |
| **Retention (days)** | 🟢 | `14` |
| **Destination ARN match** | 🟢 | `does NOT match log group ARN` |

## CloudWatch Alarm (ALB 5xx) + SNS actions
- Alarm exists: `lab-1c-alb-5xx`
- Alarm actions: `arn:aws:sns:ap-northeast-1:261519058382:lab-db-incidents`

## CloudWatch Dashboard
- Dashboard output: `lab-1c-alb-dashboard`
- Exists: `lab-1c-alb-dashboard`

## SNS Subscriptions (mandatory)
```
------------------------------------------------------------------------------------------------------------------------
|                                               ListSubscriptionsByTopic                                               |
+----------------------------------------------------------------------------------------------------------------------+
||                                                    Subscriptions                                                   ||
|+-----------------+--------------------------------------------------------------------------------------------------+|
||  Endpoint       |  selacious@outlook.com                                                                        ||
||  Owner          |  <REDACTED>                                                                                   ||
||  Protocol       |  email                                                                                           ||
||  SubscriptionArn|  arn:aws:sns:ap-northeast-1:261519058382:lab-db-incidents:c68ffa43-a642-4354-9987-92a909b46367   ||
||  TopicArn       |  arn:aws:sns:ap-northeast-1:261519058382:lab-db-incidents                                        ||
|+-----------------+--------------------------------------------------------------------------------------------------+|
```

## HTTP/HTTPS (curl -I)
- HTTPS: `HTTP/2 200 
`
- HTTP:  `HTTP/1.1 301 Moved Permanently
`

## Help
- If DNS is 🔴: confirm ALIAS exists and wait for propagation; re-run `dig app.devlab405.click +short`
- If WAF logging is 🔴: ensure `aws_wafv2_web_acl_logging_configuration` exists and CW log group name begins with `aws-waf-logs-`
- If alarm/dashboard missing: confirm ingress module created them and root outputs reference module outputs
