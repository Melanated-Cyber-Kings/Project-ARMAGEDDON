# Bonus C — CLI Validation Report
Generated (UTC): 2026-02-02 21:31:23Z
Region: ap-northeast-1

## Terraform Outputs
- FQDN: `app.devlab405.click`
- ALB ARN: `arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:loadbalancer/app/lab-1c-alb/0ec8099f68742049`
- Target Group ARN: `arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:targetgroup/lab-1c-tg/0bed57c89b471c82`
- ACM Cert ARN: `arn:aws:acm:ap-northeast-1:261519058382:certificate/31e54cd4-31d3-46e1-8f04-971f3dc50fce`
- WAF ARN: `arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/d0bb02e2-feb3-41b7-8d39-6382e00b0161`
- Alarm Name: `lab-1c-alb-5xx`
- Dashboard Name: `lab-1c-alb-dashboard`

## ALB Status
- State: `active`
- DNS: `lab-1c-alb-961069030.ap-northeast-1.elb.amazonaws.com`

## ALB Listeners
```
---------------------------------------
|          DescribeListeners          |
+----------------+-------+------------+
|  DefaultAction | Port  | Protocol   |
+----------------+-------+------------+
|  forward       |  443  |  HTTPS     |
|  redirect      |  80   |  HTTP      |
+----------------+-------+------------+
```

## Target Health
```
-------------------------------------------------------------
|                   DescribeTargetHealth                    |
+--------------+---------+----------+-----------------------+
|  Description | Reason  |  State   |        Target         |
+--------------+---------+----------+-----------------------+
|  None        |  None   |  healthy |  i-0aa5eb7af733e4749  |
+--------------+---------+----------+-----------------------+
```

## WAF Attached
```
-----------------------------------------------------------------------------------------------------------------------
|                                                GetWebACLForResource                                                 |
+------+--------------------------------------------------------------------------------------------------------------+
|  Arn |  arn:aws:wafv2:ap-northeast-1:261519058382:regional/webacl/lab-1c-waf/d0bb02e2-feb3-41b7-8d39-6382e00b0161   |
|  Name|  lab-1c-waf                                                                                                  |
+------+--------------------------------------------------------------------------------------------------------------+
```

## ACM Certificate
- ARN: `arn:aws:acm:ap-northeast-1:261519058382:certificate/31e54cd4-31d3-46e1-8f04-971f3dc50fce`
- Status: `ISSUED`

## Route53 Alias Record
```
-----------------------------------------------------------------------------------------
|                                ListResourceRecordSets                                 |
+-----------------------+----+----------------------------------------------------------+
|  app.devlab405.click. |  A |  lab-1c-alb-961069030.ap-northeast-1.elb.amazonaws.com.  |
+-----------------------+----+----------------------------------------------------------+
```

## CloudWatch Alarm
```
----------------------------------
|         DescribeAlarms         |
+-----------------+-----+--------+
|  lab-1c-alb-5xx |  OK |  10.0  |
+-----------------+-----+--------+
```

## CloudWatch Dashboard
```
lab-1c-alb-dashboard
```

## HTTP/HTTPS (curl -I)
### HTTPS
```
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed

  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  0    93    0     0    0     0      0      0 --:--:--  0:00:01 --:--:--     0
HTTP/2 200 
date: Mon, 02 Feb 2026 21:31:35 GMT
content-type: text/html; charset=utf-8
content-length: 93
server: Werkzeug/3.1.5 Python/3.9.25

```

### HTTP
```
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed

  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  0   134    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
HTTP/1.1 301 Moved Permanently
Server: awselb/2.0
Date: Mon, 02 Feb 2026 21:31:36 GMT
Content-Type: text/html
Content-Length: 134
Connection: keep-alive
Location: https://app.devlab405.click:443/

```

