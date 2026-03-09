Student verification (CLI) — DNS + Logs

1) Verify apex record exists

aws route53 list-resource-record-sets 
--hosted-zone-id Z024936810SNP2IVKNJY3 
--query "ResourceRecordSets[?Name=='tritechsite.com.']"

[
    {
        "Name": "tritechsite.com.",
        "Type": "A",
        "AliasTarget": {
            "HostedZoneId": "Z14GRHDCWA56QT",
            "DNSName": "armageddon-class-vii-alb01-866112400.ap-northeast-1.elb.amazonaws.com.",
            "EvaluateTargetHealth": true
        }
    },
    {
        "Name": "tritechsite.com.",
        "Type": "NS",
        "TTL": 172800,
        "ResourceRecords": [
            {
                "Value": "ns-506.awsdns-63.com."
            },
            {
                "Value": "ns-1903.awsdns-45.co.uk."
            },
            {
                "Value": "ns-1273.awsdns-31.org."
            },
            {
                "Value": "ns-677.awsdns-20.net."
            }
        ]
    },
    {
        "Name": "tritechsite.com.",
        "Type": "SOA",
        "TTL": 900,
        "ResourceRecords": [
            {
                "Value": "ns-506.awsdns-63.com. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"
            }
        ]
    }
]


2) Verify ALB logging is enabled

aws elbv2 describe-load-balancers  
--names armageddon-class-vii-alb01  
--query "LoadBalancers[0].LoadBalancerArn"

"arn:aws:elasticloadbalancing:ap-northeast-1:420228061920:loadbalancer/app/armageddon-class-vii-alb01/202e960cc5b39f1d"


aws elbv2 describe-load-balancer-attributes 
--load-balancer-arn "arn:aws:elasticloadbalancing:ap-northeast-1:420228061920:loadbalancer/app/armageddon-class-vii-alb01/202e960cc5b39f1d"
{
    "Attributes": [
        {
            "Key": "access_logs.s3.enabled",
            "Value": "true"
        },
        {
            "Key": "access_logs.s3.bucket",
            "Value": "armageddon-class-vii-alb-logs-420228061920"
        },
        {
            "Key": "access_logs.s3.prefix",
            "Value": "alb-access-logs"
        },
        {
            "Key": "health_check_logs.s3.enabled",
            "Value": "false"
        },
        {
            "Key": "health_check_logs.s3.bucket",
            "Value": ""
        },
        {
            "Key": "health_check_logs.s3.prefix",
            "Value": ""
        },
        {
            "Key": "idle_timeout.timeout_seconds",
            "Value": "60"
        },
        {
            "Key": "deletion_protection.enabled",
            "Value": "false"
        },
        {
            "Key": "routing.http2.enabled",
            "Value": "true"
        },
        {
            "Key": "routing.http.drop_invalid_header_fields.enabled",
            "Value": "false"
        },
        {
            "Key": "routing.http.xff_client_port.enabled",
            "Value": "false"
        },
        {
            "Key": "routing.http.preserve_host_header.enabled",
            "Value": "false"
        },
        {
            "Key": "routing.http.xff_header_processing.mode",
            "Value": "append"
        },
        {
            "Key": "load_balancing.cross_zone.enabled",
            "Value": "true"
        },
        {
            "Key": "routing.http.desync_mitigation_mode",
            "Value": "defensive"
        },
        {
            "Key": "client_keep_alive.seconds",
            "Value": "3600"
        },
        {
            "Key": "waf.fail_open.enabled",
            "Value": "false"
        },
        {
            "Key": "routing.http.x_amzn_tls_version_and_cipher_suite.enabled",
            "Value": "false"
        },
        {
            "Key": "zonal_shift.config.enabled",
            "Value": "false"
        },
        {
            "Key": "connection_logs.s3.enabled",
            "Value": "false"
        },
        {
            "Key": "connection_logs.s3.bucket",
            "Value": ""
        },
        {
            "Key": "connection_logs.s3.prefix",
            "Value": ""
        }
    ]
}



3) aws s3 ls s3://armageddon-class-vii-alb-logs-420228061920/alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ --recursive 


2026-03-04 21:04:35        361 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2105Z_176.32.72.129_63tt5a56.log.gz
2026-03-04 21:10:05       1484 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2110Z_13.158.241.175_18aonoc5.log.gz
2026-03-04 21:10:05       1920 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2110Z_176.32.72.129_5r5zfur9.log.gz
2026-03-04 21:15:05        358 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2115Z_176.32.72.129_2t2qxk0f.log.gz
2026-03-04 21:25:02        965 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2125Z_13.158.241.175_yakf1bzi.log.gz
2026-03-04 21:25:02        745 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2125Z_176.32.72.129_19idw5ti.log.gz
2026-03-04 21:30:11       1199 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2130Z_13.158.241.175_36cb4l4v.log.gz
2026-03-04 21:30:11       1068 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2130Z_176.32.72.129_1fx2hvc9.log.gz
2026-03-04 21:26:41       1350 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2130Z_176.32.72.129_dp7d0kji.log.gz
2026-03-04 21:35:11       1875 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2135Z_13.158.241.175_43xgxxuz.log.gz
2026-03-04 21:35:11       1925 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2135Z_176.32.72.129_4wc4bd9l.log.gz
2026-03-04 21:39:54        819 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2140Z_13.158.241.175_66mcxk8g.log.gz
2026-03-04 21:39:54       1631 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2140Z_176.32.72.129_2itzmf2o.log.gz
2026-03-04 21:45:04        536 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2145Z_13.158.241.175_16ni5nm0.log.gz
2026-03-04 21:45:04        823 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2145Z_176.32.72.129_5v3b0kom.log.gz
2026-03-04 21:50:04        712 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2150Z_13.158.241.175_gqr7yadv.log.gz
2026-03-04 21:55:04       3292 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2155Z_176.32.72.129_5nckmwdx.log.gz
2026-03-04 22:00:04        596 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2200Z_13.158.241.175_4rdwupk3.log.gz
2026-03-04 22:00:04       1952 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2200Z_176.32.72.129_62v0lwxs.log.gz
2026-03-04 22:05:04       3808 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2205Z_176.32.72.129_3ifovywo.log.gz
2026-03-04 22:10:04       1167 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2210Z_13.158.241.175_5uabv57v.log.gz
2026-03-04 22:10:04       2629 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2210Z_176.32.72.129_2pf6b8xx.log.gz
2026-03-04 22:15:05        825 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2215Z_13.158.241.175_3xpwqayu.log.gz
2026-03-04 22:15:04       1677 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2215Z_176.32.72.129_16sua966.log.gz
2026-03-04 22:20:04        720 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2220Z_176.32.72.129_47xkovsl.log.gz
2026-03-04 22:25:05       1120 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2225Z_13.158.241.175_8xz5gtc7.log.gz
2026-03-04 22:25:05        578 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2225Z_176.32.72.129_3oezf7x6.log.gz
2026-03-04 22:30:05        892 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2230Z_13.158.241.175_6dk72ymj.log.gz
2026-03-04 22:35:05        278 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2235Z_13.158.241.175_3wpzannu.log.gz
2026-03-04 22:35:05        509 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2235Z_176.32.72.129_68u8wh2o.log.gz
2026-03-04 22:40:05       1235 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2240Z_13.158.241.175_2b110urb.log.gz
2026-03-04 22:40:05        319 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2240Z_176.32.72.129_3bsw2xpn.log.gz
2026-03-04 22:45:05       1804 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2245Z_13.158.241.175_usayr94v.log.gz
2026-03-04 22:45:05        806 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2245Z_176.32.72.129_ku07x4km.log.gz
2026-03-04 22:50:05        643 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2250Z_176.32.72.129_29a58wdw.log.gz
2026-03-04 22:55:05       1193 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2255Z_13.158.241.175_2eksac6f.log.gz
2026-03-04 22:55:05       1091 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2255Z_176.32.72.129_d56u3rch.log.gz
2026-03-04 23:00:05       1158 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2300Z_176.32.72.129_2u24o6jl.log.gz
2026-03-04 23:05:06        870 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2305Z_13.158.241.175_c2l3andf.log.gz
2026-03-04 23:05:05       2301 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2305Z_176.32.72.129_4tadzxau.log.gz
2026-03-04 23:10:06       1154 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2310Z_13.158.241.175_4qswrckm.log.gz
2026-03-04 23:10:05        362 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2310Z_176.32.72.129_2f4y4zrc.log.gz
2026-03-04 23:15:06        396 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2315Z_13.158.241.175_dx4m10br.log.gz
2026-03-04 23:15:05        908 alb-access-logs/AWSLogs/420228061920/elasticloadbalancing/ap-northeast-1/2026/03/04/420228061920_elasticloadbalancing_ap-northeast-1_app.armageddon-class-vii-alb01.202e960cc5b39f1d_20260304T2315Z_176.32.72.129_x4n7t7ga.log.gz


4) Generate some traffic
  curl -I https://app.tritechsite.com

  HTTP/1.1 200 OK
Date: Wed, 04 Mar 2026 23:23:35 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 93
Connection: keep-alive
Server: Werkzeug/3.1.6 Python/3.9.25