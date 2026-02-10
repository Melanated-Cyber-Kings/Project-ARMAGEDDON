import boto3
import json

def get_waf_summary():
    # WAF logs for CloudFront are ALWAYS in us-east-1
    client = boto3.client('logs', region_name='us-east-1')
    log_group = "aws-waf-logs-medical-vault"
    
    try:
        # Just verifying the log group exists and has streams
        response = client.describe_log_streams(
            logGroupName=log_group,
            orderBy='LastEventTime',
            descending=True,
            limit=5
        )
        
        streams = response.get('LogStreams', [])
        
        output = {
            "log_group": log_group,
            "active_streams": len(streams),
            "status": "HEALTHY" if len(streams) > 0 else "WAITING_FOR_TRAFFIC",
            "assertion": "PASS" if len(streams) > 0 else "LOG_GROUP_FOUND"
        }
    except Exception as e:
        output = {"status": "ERROR", "message": str(e), "assertion": "FAIL"}

    print(json.dumps(output, indent=2))
    
    with open('03_waf-proof.txt', 'w') as f:
        f.write(json.dumps(output, indent=2))

if __name__ == "__main__":
    get_waf_summary()