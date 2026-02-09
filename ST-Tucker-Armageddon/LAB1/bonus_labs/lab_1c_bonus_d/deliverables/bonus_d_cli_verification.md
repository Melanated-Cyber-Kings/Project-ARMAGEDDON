## Student verification (CLI) — DNS + Logs

## Verify APEX record exists in Route 53

aws route53 list-resource-record-sets \
--hosted-zone-id Z103851437PNELROEQ0AM \
--query "ResourceRecordSets[?Name=='devlab405.click.']" --output table

--------------------------------------------------------------------------------------------------------
|                                        ListResourceRecordSets                                        |
+---------------------------------------------------------+--------------------+-----------------------+
|                          Name                           |        TTL         |         Type          |
+---------------------------------------------------------+--------------------+-----------------------+
|  devlab405.click.                                       |                    |  A                    |
+---------------------------------------------------------+--------------------+-----------------------+
||                                             AliasTarget                                            ||
|+---------------------------------------------------------+-----------------------+------------------+|
||                         DNSName                         | EvaluateTargetHealth  |  HostedZoneId    ||
|+---------------------------------------------------------+-----------------------+------------------+|
||  lab-1c-alb-836917220.ap-northeast-1.elb.amazonaws.com. |  True                 |  Z14GRHDCWA56QT  ||
|+---------------------------------------------------------+-----------------------+------------------+|
|                                        ListResourceRecordSets                                        |
+-----------------------------------------------------+--------------------------+---------------------+
|                        Name                         |           TTL            |        Type         |
+-----------------------------------------------------+--------------------------+---------------------+
|  devlab405.click.                                   |  172800                  |  NS                 |
+-----------------------------------------------------+--------------------------+---------------------+
||                                           ResourceRecords                                          ||
|+----------------------------------------------------------------------------------------------------+|
||                                                Value                                               ||
|+----------------------------------------------------------------------------------------------------+|
||  ns-1697.awsdns-20.co.uk.                                                                          ||
||  ns-1350.awsdns-40.org.                                                                            ||
||  ns-914.awsdns-50.net.                                                                             ||
||  ns-496.awsdns-62.com.                                                                             ||
|+----------------------------------------------------------------------------------------------------+|
|                                        ListResourceRecordSets                                        |
+---------------------------------------------------------+--------------------+-----------------------+
|                          Name                           |        TTL         |         Type          |
+---------------------------------------------------------+--------------------+-----------------------+
|  devlab405.click.                                       |  900               |  SOA                  |
+---------------------------------------------------------+--------------------+-----------------------+
||                                           ResourceRecords                                          ||
|+----------------------------------------------------------------------------------------------------+|
||                                                Value                                               ||
|+----------------------------------------------------------------------------------------------------+|
||  ns-1697.awsdns-20.co.uk. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400                   ||
|+----------------------------------------------------------------------------------------------------+|


## Verify Application Load Balancer logging is enabled

aws elbv2 describe-load-balancers \
--names lab-1c-alb \
--query "LoadBalancers[0].LoadBalancerArn"


"arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:loadbalancer/app/lab-1c-alb/fd1a7f35af65fc49"

## Verify load balancer attributes
aws elbv2 describe-load-balancer-attributes \
--load-balancer-arn arn:aws:elasticloadbalancing:ap-northeast-1:261519058382:loadbalancer/app/lab-1c-alb/fd1a7f35af65fc49 \
--output table

------------------------------------------------------------------------------------------------
|                                DescribeLoadBalancerAttributes                                |
+----------------------------------------------------------------------------------------------+
||                                         Attributes                                         ||
|+-----------------------------------------------------------+--------------------------------+|
||                            Key                            |             Value              ||
|+-----------------------------------------------------------+--------------------------------+|
||  access_logs.s3.enabled                                   |  true                          ||
||  access_logs.s3.bucket                                    |  lab-1c-alb-logs-261519058382  ||
||  access_logs.s3.prefix                                    |  alb-access-logs               ||
||  health_check_logs.s3.enabled                             |  false                         ||
||  health_check_logs.s3.bucket                              |                                ||
||  health_check_logs.s3.prefix                              |                                ||
||  idle_timeout.timeout_seconds                             |  60                            ||
||  deletion_protection.enabled                              |  false                         ||
||  routing.http2.enabled                                    |  true                          ||
||  routing.http.drop_invalid_header_fields.enabled          |  false                         ||
||  routing.http.xff_client_port.enabled                     |  false                         ||
||  routing.http.preserve_host_header.enabled                |  false                         ||
||  routing.http.xff_header_processing.mode                  |  append                        ||
||  load_balancing.cross_zone.enabled                        |  true                          ||
||  routing.http.desync_mitigation_mode                      |  defensive                     ||
||  client_keep_alive.seconds                                |  3600                          ||
||  waf.fail_open.enabled                                    |  false                         ||
||  routing.http.x_amzn_tls_version_and_cipher_suite.enabled |  false                         ||
||  zonal_shift.config.enabled                               |  false                         ||
||  connection_logs.s3.enabled                               |  false                         ||
||  connection_logs.s3.bucket                                |                                ||
||  connection_logs.s3.prefix                                |                                ||
|+-----------------------------------------------------------+--------------------------------+|


## Verify logs are being delivered to the S3 bucket


$ aws --no-cli-pager s3 ls \
>   "s3://lab-1c-alb-logs-261519058382/alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/" \
>   --recursive --page-size 10
2026-02-05 20:05:11       1425 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1905Z_13.159.137.167_1qru06d0.log.gz
2026-02-05 20:05:02        855 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1905Z_35.76.153.116_52fiuzeu.log.gz
2026-02-05 20:10:11        589 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1910Z_13.159.137.167_40yy7g8x.log.gz
2026-02-05 20:10:02        698 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1910Z_35.76.153.116_4p4lonrf.log.gz
2026-02-05 20:15:02       1072 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1915Z_35.76.153.116_3ea8n45y.log.gz
2026-02-05 20:20:11        783 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1920Z_13.159.137.167_4h6w88fl.log.gz
2026-02-05 20:20:02        252 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1920Z_35.76.153.116_499qh34m.log.gz
2026-02-05 20:25:02       3347 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1925Z_35.76.153.116_4fnssruv.log.gz
2026-02-05 20:30:02      23801 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1930Z_35.76.153.116_hwq2ilja.log.gz
2026-02-05 20:35:02        253 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1935Z_35.76.153.116_92xcqhyj.log.gz
2026-02-05 20:40:12        765 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1940Z_13.159.137.167_2ff6er9o.log.gz
2026-02-05 20:40:02        656 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1940Z_35.76.153.116_9wnx25j3.log.gz
2026-02-05 20:45:12       2987 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1945Z_13.159.137.167_3e0r7lp1.log.gz
2026-02-05 20:45:02       1613 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1945Z_35.76.153.116_4x25pz7z.log.gz
2026-02-05 20:50:12        745 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1950Z_13.159.137.167_3vvwcho6.log.gz
2026-02-05 20:50:02        252 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1950Z_35.76.153.116_3m1r8s0b.log.gz
2026-02-05 20:55:12        261 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1955Z_13.159.137.167_4a9pp2qy.log.gz
2026-02-05 20:55:02       2080 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T1955Z_35.76.153.116_pk6lm6nu.log.gz
2026-02-05 21:10:12        592 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T2010Z_13.159.137.167_5afs11w0.log.gz
2026-02-05 21:10:02        376 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T2010Z_35.76.153.116_106oy5xz.log.gz
2026-02-05 21:20:12        477 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T2020Z_13.159.137.167_333szsnr.log.gz
2026-02-05 21:20:02       1323 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T2020Z_35.76.153.116_3yxawa8g.log.gz
2026-02-05 21:25:12       1147 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T2025Z_13.159.137.167_j82wrdf9.log.gz
2026-02-05 21:30:03        774 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T2030Z_35.76.153.116_2e681e9m.log.gz
2026-02-05 21:35:12       2839 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T2035Z_13.159.137.167_4ur5t9i7.log.gz
2026-02-05 21:35:03       1516 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T2035Z_35.76.153.116_26dfyf59.log.gz
2026-02-05 21:40:03       1087 alb-access-logs/AWSLogs/261519058382/elasticloadbalancing/ap-northeast-1/2026/02/05/261519058382_elasticloadbalancing_ap-northeast-1_app.lab-1c-alb.fd1a7f35af65fc49_20260205T2040Z_35.76.153.116_2vljxn1s.log.gz