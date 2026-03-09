A) WAF Queries (CloudWatch Logs Insights) 

    A1) “What’s happening right now?” (Top actions: ALLOW/BLOCK) fields @timestamp, action | stats count() as hits by action | sort hits desc
    
    fields @timestamp, action
  | stats count() as hits by action
  | sort hits desc
[
    {
        "action": "",
        "hits": "670"
    },
    {
        "action": "ALLOW",
        "hits": "447"
    },
    {
        "action": "BLOCK",
        "hits": "37"
    }
]

A2) Top client IPs (who is hitting us the most?)
  fields @timestamp, httpRequest.clientIp as clientIp
| stats count() as hits by clientIp
| sort hits desc
| limit 25

[[
    {
        "clientIp": "",
        "hits": "669"
    },
    {
        "clientIp": "185.177.72.60",
        "hits": "446"
    },
    {
        "clientIp": "195.178.110.64",
        "hits": "3"
    },
    {
        "clientIp": "154.47.30.104",
        "hits": "2"
    },
    {
        "clientIp": "204.76.203.8",
        "hits": "2"
    },
    {
        "clientIp": "103.196.9.63",
        "hits": "2"
    },
    {
        "clientIp": "204.76.203.212",
        "hits": "2"
    },
    {
        "clientIp": "185.242.226.113",
        "hits": "2"
    },
    {
        "clientIp": "176.97.70.122",
        "hits": "2"
    },
    {
        "clientIp": "27.148.196.43",
        "hits": "2"
    },
    {
        "clientIp": "45.156.128.49",
        "hits": "2"
    },
    {
        "clientIp": "74.7.175.138",
        "hits": "2"
    },
    {
        "clientIp": "154.36.110.84",
        "hits": "2"
    },
    {
        "clientIp": "43.135.36.201",
        "hits": "2"
    },
    {
        "clientIp": "135.237.125.146",
        "hits": "1"
    },
    {
        "clientIp": "45.194.92.25",
        "hits": "1"
    },
    {
        "clientIp": "103.4.251.17",
        "hits": "1"
    },
    {
        "clientIp": "34.52.219.24",
        "hits": "1"
    },
    {
        "clientIp": "111.37.200.192",
        "hits": "1"
    },
    {
        "clientIp": "195.3.221.8",
        "hits": "1"
    },
    {
        "clientIp": "49.51.141.76",
        "hits": "1"
    },
    {
        "clientIp": "35.77.127.224",
        "hits": "1"
    },
    {
        "clientIp": "198.235.24.97",
        "hits": "1"
    },
    {
        "clientIp": "16.144.17.106",
        "hits": "1"
    },
    {
        "clientIp": "20.65.168.78",
        "hits": "1"
    }
]

A3) Top requested URIs (what are they trying to reach?)
  fields @timestamp, httpRequest.uri as uri
| stats count() as hits by uri
| sort hits desc
| limit 25
 
[
    {
        "uri": "",
        "hits": "670"
    },
    {
        "uri": "/",
        "hits": "30"
    },
    {
        "uri": "/robots.txt",
        "hits": "4"
    },
    {
        "uri": "/.env.stripe",
        "hits": "2"
    },
    {
        "uri": "/checkout",
        "hits": "2"
    },
    {
        "uri": "/config.js",
        "hits": "2"
    },
    {
        "uri": "/database/.env",
        "hits": "2"
    },
    {
        "uri": "/.env.dev",
        "hits": "2"
    },
    {
        "uri": "/api/payment/config",
        "hits": "2"
    },
    {
        "uri": "/secrets.yaml",
        "hits": "2"
    },
    {
        "uri": "/backup/stripe.json",
        "hits": "2"
    },
    {
        "uri": "/index.html",
        "hits": "2"
    },
    {
        "uri": "/order",
        "hits": "2"
    },
    {
        "uri": "/api/shared/config/config.env",
        "hits": "2"
    },
    {
        "uri": "/debug/default/view",
        "hits": "2"
    },
    {
        "uri": "/.env.backup",
        "hits": "2"
    },
    {
        "uri": "/stripe.key",
        "hits": "2"
    },
    {
        "uri": "/env/.env",
        "hits": "2"
    },
    {
        "uri": "/wp-config.old",
        "hits": "2"
    },
    {
        "uri": "/storage/.env",
        "hits": "2"
    },
    {
        "uri": "/_profiler/latest",
        "hits": "2"
    },
    {
        "uri": "/shop",
        "hits": "2"
    },
    {
        "uri": "/admin/settings",
        "hits": "2"
    },
    {
        "uri": "/stripe.txt",
        "hits": "2"
    },
    {
        "uri": "/site/.env",
        "hits": "2"
    }
]
A4) Blocked requests only (who/what is being blocked?)
  fields @timestamp, action, httpRequest.clientIp as clientIp, httpRequest.uri as uri
| filter action = "BLOCK"
| stats count() as blocks by clientIp, uri
| sort blocks desc
| limit 25


[
    {
        "clientIp": "185.177.72.60",
        "uri": "/wp-config.php.bak",
        "blocks": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/stripe.log",
        "blocks": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.aws/credentials",
        "blocks": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/storage/logs/laravel.log",
        "blocks": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.bak",
        "blocks": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.backup",
        "blocks": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/stripe.conf",
        "blocks": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/debug.log",
        "blocks": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/wp-content/debug.log",
        "blocks": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/storage/logs/stripe.log",
        "blocks": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/stripe.backup",
        "blocks": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/storage/logs/payments.log",
        "blocks": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/stripe.ini",
        "blocks": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/env.backup",
        "blocks": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/error.log",
        "blocks": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/stripe.bak",
        "blocks": "2"
    },
    {
        "clientIp": "176.97.70.122",
        "uri": "/stream",
        "blocks": "2"
    },
    {
        "clientIp": "20.65.168.78",
        "uri": "/",
        "blocks": "1"
    },
    {
        "clientIp": "35.77.127.224",
        "uri": "/ws/btcusdt@bookTicker",
        "blocks": "1"
    }
]



A5) Which WAF rule is doing the blocking?
  fields @timestamp, action, terminatingRuleId, terminatingRuleType
| filter action = "BLOCK"
| stats count() as blocks by terminatingRuleId, terminatingRuleType
| sort blocks desc
| limit 25

[
    {
        "terminatingRuleId": "AWSManagedRulesCommonRuleSet",
        "terminatingRuleType": "MANAGED_RULE_GROUP",
        "blocks": "36"
    }
]


A6) Rate of blocks over time (did it spike?)
  fields @timestamp, httpRequest.clientIp as clientIp, httpRequest.uri as uri
|filter uri =~ /wp-login|xmlrpc|\.env|admin|phpmyadmin|\.git|\/login/
| stats count() as hits by clientIp, uri
| sort hits desc
| limit 50

[[
    {
        "clientIp": "94.26.106.205",
        "uri": "/wp-login.php",
        "hits": "3"
    },
    {
        "clientIp": "94.26.106.205",
        "uri": "/wp-admin/",
        "hits": "3"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/tests/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/stripe/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/src/config/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/tmp/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.vite",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/env/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/app/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/api/config.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/laravel/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/rest/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/src/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/public/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/admin",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.stage",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/kyc/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/config/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/v2/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/old/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.prod",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/portal/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.staging",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/assets/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/apps/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.git/config",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.vscode/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/api/shared/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/server/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/api/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.example",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/stripe.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/admin/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/graphql/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.production",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/backup/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/site/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.local",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/backend/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.git/HEAD",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.backup",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/payment/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/mail/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/web/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/development/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.bak",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/www/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.dist",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/conf/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/local/.env",
        "hits": "2"
    }
]

A7) Suspicious scanners (common patterns: admin paths, wp-login, etc.)
  fields @timestamp, httpRequest.clientIp as clientIp, httpRequest.uri as uri
| filter uri like /wp-login|xmlrpc|\.env|admin|phpmyadmin|\.git|\/login/
| stats count() as hits by clientIp, uri
| sort hits desc
| limit 50

[
    {
        "clientIp": "94.26.106.205",
        "uri": "/wp-login.php",
        "hits": "3"
    },
    {
        "clientIp": "94.26.106.205",
        "uri": "/wp-admin/",
        "hits": "3"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/tests/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.staging",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/env/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/tmp/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/portal/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.example",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/rest/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/public/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.stage",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/kyc/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/old/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.prod",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/assets/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/apps/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/stripe.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/admin/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/v2/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/development/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/backend/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/local/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/config/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/site/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/api/config.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.vite",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/src/config/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/backup/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.local",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.old",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.bak",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/www/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.dist",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/payment/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.env.backup",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/mail/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/application/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/conf/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/stripe/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/app/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/laravel/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/src/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/api/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/server/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/admin",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/api/shared/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.git/config",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/.vscode/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/web/.env",
        "hits": "2"
    },
    {
        "clientIp": "185.177.72.60",
        "uri": "/graphql/.env",
        "hits": "2"
    }
]



A8) Country/geo (if present in your WAF logs)
Some WAF log formats include httpRequest.country. If yours does:
  fields @timestamp, httpRequest.country as country
| stats count() as hits by country
| sort hits desc
| limit 25

[
    {
        "country": "",
        "hits": "674"
    },
    {
        "country": "FR",
        "hits": "446"
    },
    {
        "country": "US",
        "hits": "13"
    },
    {
        "country": "DE",
        "hits": "6"
    },
    {
        "country": "NL",
        "hits": "4"
    },
    {
        "country": "JP",
        "hits": "3"
    },
    {
        "country": "PT",
        "hits": "2"
    },
    {
        "country": "HK",
        "hits": "2"
    },
    {
        "country": "CN",
        "hits": "2"
    },
    {
        "country": "ZA",
        "hits": "2"
    },
    {
        "country": "PL",
        "hits": "1"
    },
    {
        "country": "BE",
        "hits": "1"
    }
]


B) App Queries (EC2 app log group)
These assume your app logs include meaningful strings like ERROR, DBConnectionErrors, timeout, etc
(You should enforce this.)

B1) Count errors over time (this should line up with the alarm window)
  fields @timestamp, @message
| filter @message =~ /(ERROR|Exception|Traceback|DB|timeout|refused)/
| stats count() as errors by bin(1m)
| sort asc

  [
    {
        "bin(1m)": "2026-03-04 23:42:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:24:00.000",
        "errors": "419"
    },
    {
        "bin(1m)": "2026-03-04 23:32:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:08:00.000",
        "errors": "6"
    },
    {
        "bin(1m)": "2026-03-04 23:30:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:04:00.000",
        "errors": "7"
    },
    {
        "bin(1m)": "2026-03-04 23:52:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:15:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:27:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:29:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:11:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:10:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:23:00.000",
        "errors": "5"
    },
    {
        "bin(1m)": "2026-03-04 23:09:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:46:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:06:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:51:00.000",
        "errors": "8"
    },
    {
        "bin(1m)": "2026-03-04 23:12:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:47:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:53:00.000",
        "errors": "7"
    },
    {
        "bin(1m)": "2026-03-04 22:59:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:31:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:13:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:19:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:33:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:14:00.000",
        "errors": "9"
    },
    {
        "bin(1m)": "2026-03-04 23:39:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:35:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:05:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:02:00.000",
        "errors": "5"
    },
    {
        "bin(1m)": "2026-03-04 22:57:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:26:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:00:00.000",
        "errors": "5"
    },
    {
        "bin(1m)": "2026-03-04 23:20:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:55:00.000",
        "errors": "2"
    },
    {
        "bin(1m)": "2026-03-04 23:17:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:03:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:21:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:48:00.000",
        "errors": "5"
    },
    {
        "bin(1m)": "2026-03-04 23:18:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:43:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:49:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:25:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:54:00.000",
        "errors": "2"
    },
    {
        "bin(1m)": "2026-03-04 23:07:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:50:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:41:00.000",
        "errors": "5"
    },
    {
        "bin(1m)": "2026-03-04 23:01:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:16:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 22:58:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:28:00.000",
        "errors": "6"
    },
    {
        "bin(1m)": "2026-03-04 23:45:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:34:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:38:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:37:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:22:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:40:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:44:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:36:00.000",
        "errors": "4"
    }
]
  
  
############################################


B) App Queries (EC2 app log group)
These assume your app logs include meaningful strings like ERROR, DBConnectionErrors, timeout, etc
(You should enforce this.)

B1) Count errors over time (this should line up with the alarm window)
  fields @timestamp, @message
| filter @message =~ /(ERROR|Exception|Traceback|DB|timeout|refused)/
| stats count() as errors by bin(1m)
| sort asc
[[
    {
        "bin(1m)": "2026-03-04 23:42:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:24:00.000",
        "errors": "419"
    },
    {
        "bin(1m)": "2026-03-04 23:30:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:29:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:27:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:23:00.000",
        "errors": "5"
    },
    {
        "bin(1m)": "2026-03-04 23:32:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:46:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:47:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:53:00.000",
        "errors": "7"
    },
    {
        "bin(1m)": "2026-03-04 23:31:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:33:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:35:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:39:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:55:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:51:00.000",
        "errors": "8"
    },
    {
        "bin(1m)": "2026-03-04 23:52:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 22:57:00.000",
        "errors": "2"
    },
    {
        "bin(1m)": "2026-03-04 23:08:00.000",
        "errors": "6"
    },
    {
        "bin(1m)": "2026-03-04 23:04:00.000",
        "errors": "7"
    },
    {
        "bin(1m)": "2026-03-04 23:15:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:10:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:09:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:06:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:12:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:26:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:19:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 22:59:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:13:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:11:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:02:00.000",
        "errors": "5"
    },
    {
        "bin(1m)": "2026-03-04 23:00:00.000",
        "errors": "5"
    },
    {
        "bin(1m)": "2026-03-04 23:20:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:14:00.000",
        "errors": "9"
    },
    {
        "bin(1m)": "2026-03-04 23:05:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:37:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:38:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:21:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:48:00.000",
        "errors": "5"
    },
    {
        "bin(1m)": "2026-03-04 23:25:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:49:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:54:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:43:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:41:00.000",
        "errors": "5"
    },
    {
        "bin(1m)": "2026-03-04 23:44:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:40:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:36:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:45:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:34:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:28:00.000",
        "errors": "6"
    },
    {
        "bin(1m)": "2026-03-04 23:50:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:17:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:22:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:18:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:03:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:07:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:01:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 23:16:00.000",
        "errors": "4"
    },
    {
        "bin(1m)": "2026-03-04 22:58:00.000",
        "errors": "4"
    }
]
B2) Show the most recent DB failures (triage view)
  fields @timestamp, @message
| filter @message =~ /(DB|mysql|timeout|refused|Access denied|could not connect)/
| sort @timestamp desc
| limit 50


[
    {
        "@timestamp": "2026-03-05 00:18:59.995",
        "@message": "Traceback (most recent call last):\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 661, in connect\n    sock = socket.create_connection(\n  File \"/usr/lib64/python3.9/socket.py\", line 856, in create_connection\n    raise err\n  File \"/usr/lib64/python3.9/socket.py\", line 844, in create_connection\n    sock.connect(sa)"
    },
    {
        "@timestamp": "2026-03-05 00:18:59.995",
        "@message": "ConnectionRefusedError: [Errno 111] Connection refused\n"
    },
    {
        "@timestamp": "2026-03-05 00:18:59.995",
        "@message": "Traceback (most recent call last):\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 1511, in wsgi_app\n    response = self.full_dispatch_request()\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 919, in full_dispatch_request\n    rv = self.handle_user_exception(e)\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 917, in full_dispatch_request\n    rv = self.dispatch_request()\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 902, in dispatch_request\n    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)  # type: ignore[no-any-return]\n  File \"/opt/rdsapp/app.py\", line 90, in init_db\n    conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 365, in __init__\n    self.connect()\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 723, in connect\n    raise exc"
    },
    {
        "@timestamp": "2026-03-05 00:18:59.995",
        "@message": "pymysql.err.OperationalError: (2003, \"Can't connect to MySQL server on 'armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com' ([Errno 111] Connection refused)\")"
    },
    {
        "@timestamp": "2026-03-05 00:18:58.238",
        "@message": "Traceback (most recent call last):\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 661, in connect\n    sock = socket.create_connection(\n  File \"/usr/lib64/python3.9/socket.py\", line 856, in create_connection\n    raise err\n  File \"/usr/lib64/python3.9/socket.py\", line 844, in create_connection\n    sock.connect(sa)"
    },
    {
        "@timestamp": "2026-03-05 00:18:58.238",
        "@message": "ConnectionRefusedError: [Errno 111] Connection refused\n"
    },
    {
        "@timestamp": "2026-03-05 00:18:58.238",
        "@message": "Traceback (most recent call last):\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 1511, in wsgi_app\n    response = self.full_dispatch_request()\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 919, in full_dispatch_request\n    rv = self.handle_user_exception(e)\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 917, in full_dispatch_request\n    rv = self.dispatch_request()\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 902, in dispatch_request\n    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)  # type: ignore[no-any-return]\n  File \"/opt/rdsapp/app.py\", line 90, in init_db\n    conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 365, in __init__\n    self.connect()\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 723, in connect\n    raise exc"
    },
    {
        "@timestamp": "2026-03-05 00:18:58.238",
        "@message": "pymysql.err.OperationalError: (2003, \"Can't connect to MySQL server on 'armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com' ([Errno 111] Connection refused)\")"
    },
    {
        "@timestamp": "2026-03-05 00:18:56.481",
        "@message": "Traceback (most recent call last):\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 661, in connect\n    sock = socket.create_connection(\n  File \"/usr/lib64/python3.9/socket.py\", line 856, in create_connection\n    raise err\n  File \"/usr/lib64/python3.9/socket.py\", line 844, in create_connection\n    sock.connect(sa)"
    },
    {
        "@timestamp": "2026-03-05 00:18:56.481",
        "@message": "ConnectionRefusedError: [Errno 111] Connection refused\n"
    },
    {
        "@timestamp": "2026-03-05 00:18:56.481",
        "@message": "Traceback (most recent call last):\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 1511, in wsgi_app\n    response = self.full_dispatch_request()\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 919, in full_dispatch_request\n    rv = self.handle_user_exception(e)\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 917, in full_dispatch_request\n    rv = self.dispatch_request()\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 902, in dispatch_request\n    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)  # type: ignore[no-any-return]\n  File \"/opt/rdsapp/app.py\", line 90, in init_db\n    conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 365, in __init__\n    self.connect()\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 723, in connect\n    raise exc"
    },
    {
        "@timestamp": "2026-03-05 00:18:56.481",
        "@message": "pymysql.err.OperationalError: (2003, \"Can't connect to MySQL server on 'armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com' ([Errno 111] Connection refused)\")"
    },
    {
        "@timestamp": "2026-03-05 00:18:55.478",
        "@message": "Traceback (most recent call last):\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 661, in connect\n    sock = socket.create_connection(\n  File \"/usr/lib64/python3.9/socket.py\", line 856, in create_connection\n    raise err\n  File \"/usr/lib64/python3.9/socket.py\", line 844, in create_connection\n    sock.connect(sa)"
    },
    {
        "@timestamp": "2026-03-05 00:18:55.478",
        "@message": "ConnectionRefusedError: [Errno 111] Connection refused\n"
    },
    {
        "@timestamp": "2026-03-05 00:18:55.478",
        "@message": "Traceback (most recent call last):\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 1511, in wsgi_app\n    response = self.full_dispatch_request()\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 919, in full_dispatch_request\n    rv = self.handle_user_exception(e)\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 917, in full_dispatch_request\n    rv = self.dispatch_request()\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 902, in dispatch_request\n    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)  # type: ignore[no-any-return]\n  File \"/opt/rdsapp/app.py\", line 90, in init_db\n    conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 365, in __init__\n    self.connect()\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 723, in connect\n    raise exc"
    },
    {
        "@timestamp": "2026-03-05 00:18:55.478",
        "@message": "pymysql.err.OperationalError: (2003, \"Can't connect to MySQL server on 'armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com' ([Errno 111] Connection refused)\")"
    },
    {
        "@timestamp": "2026-03-05 00:18:54.977",
        "@message": "Traceback (most recent call last):\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 661, in connect\n    sock = socket.create_connection(\n  File \"/usr/lib64/python3.9/socket.py\", line 856, in create_connection\n    raise err\n  File \"/usr/lib64/python3.9/socket.py\", line 844, in create_connection\n    sock.connect(sa)"
    },
    {
        "@timestamp": "2026-03-05 00:18:54.977",
        "@message": "ConnectionRefusedError: [Errno 111] Connection refused\n"
    },
    {
        "@timestamp": "2026-03-05 00:18:54.977",
        "@message": "Traceback (most recent call last):\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 1511, in wsgi_app\n    response = self.full_dispatch_request()\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 919, in full_dispatch_request\n    rv = self.handle_user_exception(e)\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 917, in full_dispatch_request\n    rv = self.dispatch_request()\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 902, in dispatch_request\n    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)  # type: ignore[no-any-return]\n  File \"/opt/rdsapp/app.py\", line 90, in init_db\n    conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 365, in __init__\n    self.connect()\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 723, in connect\n    raise exc"
    },
    {
        "@timestamp": "2026-03-05 00:18:54.977",
        "@message": "pymysql.err.OperationalError: (2003, \"Can't connect to MySQL server on 'armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com' ([Errno 111] Connection refused)\")"
    },
    {
        "@timestamp": "2026-03-05 00:18:52.469",
        "@message": "Traceback (most recent call last):\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 661, in connect\n    sock = socket.create_connection(\n  File \"/usr/lib64/python3.9/socket.py\", line 856, in create_connection\n    raise err\n  File \"/usr/lib64/python3.9/socket.py\", line 844, in create_connection\n    sock.connect(sa)"
    },
    {
        "@timestamp": "2026-03-05 00:18:52.469",
        "@message": "ConnectionRefusedError: [Errno 111] Connection refused\n"
    },
    {
        "@timestamp": "2026-03-05 00:18:52.469",
        "@message": "Traceback (most recent call last):\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 1511, in wsgi_app\n    response = self.full_dispatch_request()\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 919, in full_dispatch_request\n    rv = self.handle_user_exception(e)\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 917, in full_dispatch_request\n    rv = self.dispatch_request()\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 902, in dispatch_request\n    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)  # type: ignore[no-any-return]\n  File \"/opt/rdsapp/app.py\", line 90, in init_db\n    conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 365, in __init__\n    self.connect()\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 723, in connect\n    raise exc"
    },
    {
        "@timestamp": "2026-03-05 00:18:52.469",
        "@message": "pymysql.err.OperationalError: (2003, \"Can't connect to MySQL server on 'armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com' ([Errno 111] Connection refused)\")"
    },
    {
        "@timestamp": "2026-03-05 00:18:50.212",
        "@message": "Traceback (most recent call last):\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 661, in connect\n    sock = socket.create_connection(\n  File \"/usr/lib64/python3.9/socket.py\", line 856, in create_connection\n    raise err\n  File \"/usr/lib64/python3.9/socket.py\", line 844, in create_connection\n    sock.connect(sa)"
    },
    {
        "@timestamp": "2026-03-05 00:18:50.212",
        "@message": "ConnectionRefusedError: [Errno 111] Connection refused\n"
    },
    {
        "@timestamp": "2026-03-05 00:18:50.212",
        "@message": "Traceback (most recent call last):\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 1511, in wsgi_app\n    response = self.full_dispatch_request()\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 919, in full_dispatch_request\n    rv = self.handle_user_exception(e)\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 917, in full_dispatch_request\n    rv = self.dispatch_request()\n  File \"/usr/local/lib/python3.9/site-packages/flask/app.py\", line 902, in dispatch_request\n    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)  # type: ignore[no-any-return]\n  File \"/opt/rdsapp/app.py\", line 90, in init_db\n    conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 365, in __init__\n    self.connect()\n  File \"/usr/local/lib/python3.9/site-packages/pymysql/connections.py\", line 723, in connect\n    raise exc"
    },
    {
        "@timestamp": "2026-03-05 00:18:50.212",
        "@message": "pymysql.err.OperationalError: (2003, \"Can't connect to MySQL server on 'armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com' ([Errno 111] Connection refused)\")"
    }
]




#########################################
1. Temp suspend DB in AWS Console
###########################################


B3) “Is it creds or network?” classifier hints
### Command not working
  Credentials drift often shows: Access denied, authentication failures
  Network/SecurityGroup often shows: timeout, refused, “no route”, hang
  fields @timestamp, @message
| filter @message like /Access denied|authentication failed|timeout|refused|no route|could not connect/i
| stats count() as hits by
  case(
    @message like /Access denied|authentication failed/i, "Creds/Auth",
    @message like /timeout|no route/i, "Network/Route",
    @message like /refused/i, "Port/SG/ServiceRefused",
    "Other"
  )
| sort hits desc


# used this instead
fields @timestamp, @message,
  if(@message like /(?i)Access denied|authentication failed/, "Creds/Auth",
    if(@message like /(?i)timeout|no route/, "Network/Route",
      if(@message like /(?i)refused/, "Port/SG/ServiceRefused", "Other")
    )
  ) as category
| filter @message like /Access denied|authentication failed|timeout|refused|no route|could not connect/
| stats count() as hits by category
| sort hits desc

[
    {
        "category": "Port/SG/ServiceRefused",
        "hits": "14"
    },
    {
        "category": "Network/Route",
        "hits": "6"
    }
]

###########################################
fields @timestamp, @message
| filter @message like "ERROR" or @message like "Exception" or @message like "timeout" or @message like "refused" or @message like "Access denied"
| stats count() as errors by @timestamp
| sort @timestamp asc
| limit 10
[
    {
        "@timestamp": "2026-03-04 23:32:18.497",
        "errors": "1"
    },
    {
        "@timestamp": "2026-03-04 23:32:22.558",
        "errors": "1"
    },
    {
        "@timestamp": "2026-03-04 23:32:48.584",
        "errors": "1"
    },
    {
        "@timestamp": "2026-03-04 23:32:53.558",
        "errors": "1"
    },
    {
        "@timestamp": "2026-03-04 23:33:18.429",
        "errors": "1"
    },
    {
        "@timestamp": "2026-03-04 23:33:22.558",
        "errors": "1"
    },
    {
        "@timestamp": "2026-03-04 23:33:48.520",
        "errors": "1"
    },
    {
        "@timestamp": "2026-03-04 23:33:52.557",
        "errors": "1"
    },
    {
        "@timestamp": "2026-03-04 23:34:18.607",
        "errors": "1"
    },
    {
        "@timestamp": "2026-03-04 23:34:23.558",
        "errors": "1"
    }
]





###########################################

Step 1 — Confirm signal timing
  CloudWatch alarm time window: last 5–15 minutes
  Run App B1 to see error spike time bins

Step 2 — Decide: Attack vs Backend Failure
  Run WAF A1 + A6:
    If BLOCK spikes align with incident time → likely external pressure/scanning
    If WAF is quiet but app errors spike → likely backend (RDS/SG/creds)

Step 3 — If backend failure suspected
  Run App B2 and classify:
    Access denied → secrets drift / wrong password
    timeout → SG/routing/RDS down
  Then retrieve known-good values:
    Parameter Store /lab/db/*
    Secrets Manager /<prefix>/rds/mysql

Step 4 — Verify recovery
  App errors return to baseline (B1)
  WAF blocks stabilize (A6)
  Alarm returns to OK
  curl -I https://app.tritechsite.com/list works

HTTP/1.1 200 OK
Date: Thu, 05 Mar 2026 00:39:20 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 23
Connection: keep-alive
Server: Werkzeug/3.1.6 Python/3.9.25





 aws secretsmanager update-secret --secret-id armageddon-class-vii/rds/mysql-v2 --region ap-northeast-1 --secret-string '{"username":"admin","password":"Bigpimpin6","host":"armageddon-class-vii-rds01.cvy24sayqwx1.ap-northeast-1.rds.amazonaws.com","port":3306,"dbname":"mydb"}'   
{
    "ARN": "arn:aws:secretsmanager:ap-northeast-1:420228061920:secret:armageddon-class-vii/rds/mysql-v2-EuZAIn",
    "Name": "armageddon-class-vii/rds/mysql-v2",
    "VersionId": "890de7e3-7d49-4fee-8459-d05beb18b26c"
}