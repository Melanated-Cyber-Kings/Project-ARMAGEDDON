#!/usr/bin/env python3
import boto3, time, json, argparse
from datetime import datetime, timezone, timedelta

# Reason why Darth Malgus would be pleased with this script.
# He enjoys watching attacks get denied at the edge—statistics are trophies.
# Reason why this script is relevant to your career.
# WAF analysis and false-positive detection are daily security operations.
# How you would talk about this script at an interview.
# "I standardized WAF triage by querying logs and producing an audit-friendly summary."

def run(group, region, query, minutes):
    """Run CloudWatch Logs Insights query in specified region"""
    logs = boto3.client("logs", region_name=region)
    end = int(datetime.now(timezone.utc).timestamp())
    start = int((datetime.now(timezone.utc)-timedelta(minutes=minutes)).timestamp())
    
    qid = logs.start_query(
        logGroupName=group, 
        startTime=start, 
        endTime=end, 
        queryString=query, 
        limit=50
    )["queryId"]
    
    for _ in range(30):
        r = logs.get_query_results(queryId=qid)
        if r["status"] == "Complete":
            return [{x["field"]: x["value"] for x in row} for row in r["results"]]
        time.sleep(1)
    raise TimeoutError("Query timed out")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--log-group", required=True, help="CloudWatch Logs group name")
    ap.add_argument("--region", default="us-east-1", help="AWS region for the log group (default: us-east-1 for CloudFront WAF)")
    ap.add_argument("--minutes", type=int, default=30, help="Minutes to look back")
    args = ap.parse_args()

    print(f"Querying WAF logs in {args.region} for log group: {args.log_group}")
    print(f"Time range: Last {args.minutes} minutes")
    
    # Query 1: Count by action (ALLOW, BLOCK, COUNT)
    print("\n=== WAF ACTION STATISTICS ===")
    actions = run(args.log_group, args.region, "stats count() as hits by action | sort hits desc", args.minutes)
    print(json.dumps(actions, indent=2))
    
    # Query 2: Top source IPs
    print("\n=== TOP SOURCE IPs ===")
    top_ips = run(args.log_group, args.region, "stats count() as hits by httpRequest.clientIp | sort hits desc | limit 10", args.minutes)
    print(json.dumps(top_ips, indent=2))
    
    # Query 3: Terminating rules
    print("\n=== TERMINATING RULES (BLOCK/COUNT) ===")
    terminating_rules = run(args.log_group, args.region, 
        "filter action != 'ALLOW' | stats count() as hits by terminatingRuleId | sort hits desc", 
        args.minutes)
    print(json.dumps(terminating_rules, indent=2))
    
    # Query 4: Country codes (if geo data available)
    print("\n=== TOP COUNTRIES ===")
    countries = run(args.log_group, args.region, 
        "stats count() as hits by httpRequest.country | sort hits desc | limit 10", 
        args.minutes)
    print(json.dumps(countries, indent=2))

if __name__ == "__main__":
    main()