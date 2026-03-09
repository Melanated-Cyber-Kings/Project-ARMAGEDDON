
A) WAF Queries (CloudWatch Logs Insights)
A1) "What's happening right now?" (Top actions: ALLOW/BLOCK)
The logs show that AWS WAF processed a total of 1,154 web requests during the observed period. Of these, 447 requests were explicitly allowed and 37 were blocked. A significant volume of 670 requests returned no action field, likely representing requests handled before WAF rule evaluation or logging gaps. The BLOCK rate of approximately 3.2% against logged traffic indicates active threat interception. Traffic volume is notably higher than baseline with a meaningful number of blocks recorded.

A2) Top client IPs (who is hitting us the most?)
The logs show traffic from 25 distinct client IP addresses during the observed period. One IP address, 185.177.72.60, generated 446 requests — representing the overwhelming majority of all attributed traffic and strongly suggesting automated or scripted activity. The next highest IPs each contributed only 1–3 hits, making 185.177.72.60 a clear statistical outlier. The remaining 23 IPs show normal, low-volume access patterns consistent with legitimate distributed traffic. The concentration of nearly all attributable volume in a single IP is a significant indicator of scanning or enumeration behaviour.

A3) Top requested URIs (what are they trying to reach?)
The logs show 25 distinct URIs accessed during the observed period. The root path / received the highest legitimate hit count at 30 requests. However, the broader URI pattern is highly concerning — the majority of recorded paths are credential and secrets-harvesting targets, including multiple .env file variants, Stripe payment configuration files (/stripe.key, /backup/stripe.json, /api/payment/config), database environment files (/database/.env), secrets manifests (/secrets.yaml), and debug/profiler endpoints. The presence of payment-specific probing paths indicates a targeted financial credential harvesting campaign rather than generic scanning.

A4) Blocked requests only (who/what is being blocked?)
The logs show 37 total blocks during the observed period, with 185.177.72.60 responsible for 32 of them across 16 distinct sensitive URI paths. Blocked targets include AWS credential files (/.aws/credentials), WordPress configuration backups, Laravel log files, Stripe-specific configuration files, and multiple environment backup files. Two additional IPs were blocked: 176.97.70.122 targeting /stream (2 blocks) and 35.77.127.224 targeting a cryptocurrency WebSocket endpoint /ws/btcusdt@bookTicker (1 block). The primary actor 185.177.72.60 is conducting a broad, systematic credential sweep across the application surface.

A5) Which WAF rule is doing the blocking?
The logs show that all 36 recorded blocks were terminated exclusively by AWSManagedRulesCommonRuleSet (MANAGED_RULE_GROUP). No custom rules or additional managed rule groups contributed to blocking activity. While the managed ruleset is intercepting a meaningful volume of requests, the number of suspicious URIs being allowed through (visible in A3 and A6) suggests the current ruleset may not be covering all attack vectors — particularly the Stripe-specific and payment-targeted paths.

A6) Rate of blocks over time (did it spike?)
The logs reveal two distinct actors engaging in suspicious scanning activity. IP 185.177.72.60 conducted an extensive .env file enumeration campaign, probing over 50 unique environment file paths with 2 hits each — covering virtually every common .env naming convention and directory combination. Additionally, IP 94.26.106.205 was observed targeting WordPress-specific paths, hitting both /wp-login.php and /wp-admin/ with 3 requests each. The volume and breadth of 185.177.72.60's .env enumeration in particular indicates an automated tool performing a full-dictionary sweep.

A7) Suspicious scanners (common patterns: admin paths, wp-login, etc.)
Two confirmed scanner IPs were identified. 185.177.72.60 is the primary threat actor conducting a comprehensive secrets and credential sweep across .env, .git, and Stripe-related paths — with over 50 unique suspicious URIs probed. 94.26.106.205 is a secondary actor focused specifically on WordPress attack surfaces, targeting /wp-login.php and /wp-admin/. Both actors represent automated scanning tools. 185.177.72.60's campaign is particularly notable for its financial targeting focus, probing Stripe-specific paths alongside generic secrets enumeration.

A8) Country/geo
The logs show web traffic originating from 11 countries during the observed period. France (FR) generated 446 requests, accounting for the dominant share of all attributed traffic and corresponding directly to the primary threat actor IP 185.177.72.60. The United States contributed 13 requests, Germany 6, the Netherlands 4, Japan 3, and Portugal, Hong Kong, China, and South Africa 2 each. Poland and Belgium each contributed 1 request. The strong geographic correlation between the FR country code and the high-volume scanning IP is a key attribution data point.

B) App Queries (EC2 App Log Group)
B1) Count errors over time (this should line up with the alarm window)
The logs show a consistent baseline of 4 errors per minute throughout most of the monitored period from 22:57 UTC to 23:55 UTC on March 4, 2026. A catastrophic spike occurred at 23:24 UTC with 419 errors in a single minute — over 100 times the baseline rate — representing the clear incident trigger point. Additional elevated counts were recorded at 23:14 UTC (9 errors), 23:51 UTC (8 errors), 23:04 UTC and 23:53 UTC (7 each), and 23:08 UTC and 23:28 UTC (6 each). The 419-error spike at 23:24 UTC is the definitive alarm window event and warrants primary investigation focus.

B2) Show the most recent DB failures (triage view)
Active and ongoing database failures are confirmed. All recent log entries show repeated pymysql.err.OperationalError (2003) — the application Flask layer (/opt/rdsapp/app.py, line 90) is attempting to connect to armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com and receiving ConnectionRefusedError: [Errno 111] Connection refused on every attempt. Failures are occurring at sub-second intervals as of 00:18 UTC on March 5, 2026, indicating the RDS instance is either stopped, unreachable, or has had its security group modified. This is an active, ongoing outage — not a historical event.

B3) "Is it creds or network?"
The classifier results are unambiguous. 14 hits were categorised as Port/SG/ServiceRefused and 6 as Network/Route. Zero hits for Creds/Auth. This conclusively rules out a credentials or authentication problem. The failure pattern — connection refused at the TCP level before any MySQL handshake — indicates the database port (3306) is either not accepting connections due to a Security Group rule change, the RDS instance is in a stopped or failed state, or there is a network routing/VPC issue preventing the EC2 application from reaching the RDS endpoint. This is a network/infrastructure incident, not an application or credentials incident.

Step 1: The 419-error spike at 23:24 UTC aligns directly with the alarm window, confirmed by B1.
Step 2: WAF activity shows external threat actor scanning but no application-layer breach. App errors are driven entirely by RDS connectivity failure. This is a backend infrastructure incident. The database is down or unreachable.go08:59Here is the formatted report:

A) WAF Queries (CloudWatch Logs Insights)
A1) "What's happening right now?" (Top actions: ALLOW/BLOCK)
@ observed period | ALLOW: 447 | BLOCK: 37 | NO_ACTION: 670 | aws-waf-logs-[project-webacl]
The logs show that AWS WAF processed a total of 1,154 web requests during the observed period. 447 requests were explicitly allowed and 37 were blocked. A large volume of 670 requests carried no action field, likely representing pre-rule-evaluation traffic or a logging gap. The block rate of approximately 3.2% against attributed traffic indicates active threat interception. Traffic volume is significantly elevated compared to baseline, with a meaningful and concentrated blocking pattern emerging from a single source.

A2) Top client IPs (who is hitting us the most?)
185.177.72.60   - 446 hits
195.178.110.64  -   3 hits
154.47.30.104   -   2 hits
204.76.203.8    -   2 hits
103.196.9.63    -   2 hits
204.76.203.212  -   2 hits
185.242.226.113 -   2 hits
176.97.70.122   -   2 hits
27.148.196.43   -   2 hits
45.156.128.49   -   2 hits
74.7.175.138    -   2 hits
154.36.110.84   -   2 hits
43.135.36.201   -   2 hits
[+12 IPs]       -   1 hit each
The logs show traffic from 25 distinct client IP addresses during the observed period. One IP, 185.177.72.60, generated 446 requests — representing the overwhelming majority of all attributed traffic and strongly indicating automated or scripted activity. The next highest contributors account for only 1–3 hits each, making 185.177.72.60 a clear statistical outlier. The remaining IPs show normal, low-volume patterns consistent with legitimate distributed access. The concentration of nearly all attributable volume in a single source is a strong indicator of active scanning or enumeration.

A3) Top requested URIs (what are they trying to reach?)
/                          - 30 hits
/robots.txt                -  4 hits
/.env.stripe               -  2 hits
/checkout                  -  2 hits
/config.js                 -  2 hits
/database/.env             -  2 hits
/.env.dev                  -  2 hits
/api/payment/config        -  2 hits
/secrets.yaml              -  2 hits
/backup/stripe.json        -  2 hits
/index.html                -  2 hits
/order                     -  2 hits
/api/shared/config/config.env - 2 hits
/debug/default/view        -  2 hits
/.env.backup               -  2 hits
/stripe.key                -  2 hits
/env/.env                  -  2 hits
/wp-config.old             -  2 hits
/storage/.env              -  2 hits
/_profiler/latest          -  2 hits
/shop                      -  2 hits
/admin/settings            -  2 hits
/stripe.txt                -  2 hits
/site/.env                 -  2 hits
[+additional .env variants]
The logs show 25+ distinct URIs accessed during the observed period. While the root path received the highest volume at 30 hits, the broader URI pattern is highly concerning. The majority of probed paths target credential and secrets exfiltration — multiple .env file variants, Stripe payment configuration files, database environment files, secrets manifests, and debug profiler endpoints. The presence of payment-specific paths such as /backup/stripe.json, /api/payment/config, and /stripe.key indicates a targeted financial credential harvesting campaign rather than generic opportunistic scanning.

A4) Blocked requests only (who/what is being blocked?)
185.177.72.60 | /wp-config.php.bak          - 2 blocks
185.177.72.60 | /stripe.log                 - 2 blocks
185.177.72.60 | /.aws/credentials           - 2 blocks
185.177.72.60 | /storage/logs/laravel.log   - 2 blocks
185.177.72.60 | /.env.bak                   - 2 blocks
185.177.72.60 | /.env.backup                - 2 blocks
185.177.72.60 | /stripe.conf                - 2 blocks
185.177.72.60 | /debug.log                  - 2 blocks
185.177.72.60 | /wp-content/debug.log       - 2 blocks
185.177.72.60 | /storage/logs/stripe.log    - 2 blocks
185.177.72.60 | /stripe.backup              - 2 blocks
185.177.72.60 | /storage/logs/payments.log  - 2 blocks
185.177.72.60 | /stripe.ini                 - 2 blocks
185.177.72.60 | /env.backup                 - 2 blocks
185.177.72.60 | /error.log                  - 2 blocks
185.177.72.60 | /stripe.bak                 - 2 blocks
176.97.70.122 | /stream                     - 2 blocks
20.65.168.78  | /                           - 1 block
35.77.127.224 | /ws/btcusdt@bookTicker      - 1 block
The logs show 37 total blocks during the observed period. 185.177.72.60 is responsible for 32 of them across 16 distinct sensitive URI paths, targeting AWS credential files, WordPress configuration backups, Laravel log files, and an extensive range of Stripe-specific files. Two secondary IPs were also blocked: 176.97.70.122 targeting /stream and 35.77.127.224 targeting a cryptocurrency WebSocket endpoint. The primary actor is conducting a broad, systematic credential sweep across the full application attack surface.

A5) Which WAF rule is doing the blocking?
AWSManagedRulesCommonRuleSet | MANAGED_RULE_GROUP | 36 blocks
The logs show all 36 recorded blocks were terminated exclusively by AWSManagedRulesCommonRuleSet. No custom rules or additional managed rule groups contributed to blocking activity during this period. While the managed ruleset is intercepting a meaningful volume of requests, the breadth of suspicious URIs visible in A3 and A6 that are being allowed through suggests the current ruleset does not cover all active attack vectors — particularly the Stripe-specific and payment-targeted paths which appear to be passing without block.

A6) Rate of blocks over time (did it spike?)
94.26.106.205 | /wp-login.php  - 3 hits
94.26.106.205 | /wp-admin/     - 3 hits
185.177.72.60 | [50+ .env and .git variants] - 2 hits each
The logs reveal two distinct actors engaged in suspicious scanning. 185.177.72.60 conducted an extensive enumeration campaign across 50+ unique .env file paths and .git endpoints, covering virtually every common naming convention and directory combination — consistent with an automated dictionary-sweep tool. 94.26.106.205 is a secondary actor focused on WordPress attack surfaces, targeting /wp-login.php and /wp-admin/ specifically. The volume and breadth of 185.177.72.60's campaign is the dominant pattern of concern.

A7) Suspicious scanners (common patterns: admin paths, wp-login, etc.)
94.26.106.205 | /wp-login.php - 3 hits
94.26.106.205 | /wp-admin/    - 3 hits
185.177.72.60 | /admin        - 2 hits
185.177.72.60 | /.git/config  - 2 hits
185.177.72.60 | /.git/HEAD    - 2 hits
185.177.72.60 | [48+ .env variants] - 2 hits each
Two confirmed scanner IPs were identified. 185.177.72.60 is the primary threat actor conducting a comprehensive secrets and credential sweep spanning .env, .git, Stripe, and admin paths — the most aggressive and broad scanning pattern in the dataset. 94.26.106.205 is a secondary actor focused exclusively on WordPress attack surfaces. Both represent automated tooling. 185.177.72.60's campaign is particularly notable for its financial targeting specificity, probing Stripe-named paths extensively alongside generic secrets enumeration.

A8) Country/geo
FR - 446 hits
US -  13 hits
DE -   6 hits
NL -   4 hits
JP -   3 hits
PT -   2 hits
HK -   2 hits
CN -   2 hits
ZA -   2 hits
PL -   1 hit
BE -   1 hit
The logs show web traffic originating from 11 countries during the observed period. France (FR) generated 446 requests — the dominant share of all attributed traffic — correlating directly with the primary threat actor IP 185.177.72.60. The United States contributed 13 requests, Germany 6, and the Netherlands 4. The remaining countries contributed 1–3 requests each. The strong geographic correlation between the FR country code and the high-volume scanning IP is a key attribution data point and may be relevant for geo-blocking consideration.

B) App Queries (EC2 App Log Group)
B1) Count errors over time (this should line up with the alarm window)
The logs show a consistent baseline of 4 errors per minute throughout the monitored period from 22:57 UTC to 23:55 UTC on March 4, 2026. A catastrophic spike occurred at 23:24 UTC recording 419 errors in a single minute — over 100 times the baseline rate — representing the definitive incident trigger point. Secondary elevated counts were recorded at 23:14 UTC (9 errors), 23:51 UTC (8 errors), 23:04 and 23:53 UTC (7 each), and 23:08 and 23:28 UTC (6 each). The 419-error spike at 23:24 UTC is the primary alarm window event. All other elevated minutes represent normal variance against the 4/min baseline. The error pattern is persistent and ongoing — not a transient burst.

B2) Show the most recent DB failures (triage view)
Active and ongoing database failures are confirmed. All recent log entries from 00:18 UTC on March 5, 2026 show repeated pymysql.err.OperationalError (2003) — the Flask application layer at /opt/rdsapp/app.py line 90 is attempting to connect to:
armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com
Every attempt returns ConnectionRefusedError: [Errno 111] Connection refused. Failures are occurring at sub-second intervals, confirming the RDS instance is either stopped, unreachable, or has had its security group or network configuration modified. This is an active, ongoing outage — not a historical event.

B3) "Is it creds or network?"
Port/SG/ServiceRefused - 14 hits
Network/Route          -  6 hits
Creds/Auth             -  0 hits
The classifier results are unambiguous. Zero hits for Creds/Auth conclusively rules out a credentials or authentication problem. The failure pattern — connection refused at the TCP level before any MySQL handshake is established — indicates one of the following: the RDS instance is in a stopped or failed state, Security Group rules have been modified to block port 3306 from the EC2 source, or there is a VPC routing issue preventing connectivity to the RDS endpoint. This is a network/infrastructure incident, not an application or credentials incident.

Step 1: The 419-error spike at 23:24 UTC on March 4, 2026 aligns directly with the alarm window. Confirmed by B1.
Step 2: WAF activity shows an active external threat actor (185.177.72.60) conducting a financial credential harvesting sweep, but no evidence of application-layer breach. App errors are driven entirely by RDS TCP connectivity failure. This is a backend infrastructure incident. The RDS database is down or unreachable — verify instance state, Security Group rules, and VPC routing to armageddon-class-vii-rds01 immediately.


WAF Log Group: aws-waf-logs-armageddon-class-vii-webacl01

App Log Group: /aws/ec2/armageddon-class-vii-rds-app

Verification URL: https://app.tritechsite.com/