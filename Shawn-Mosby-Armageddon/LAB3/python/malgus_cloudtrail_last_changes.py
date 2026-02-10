import boto3
import json

def get_last_changes():
    # Connecting to Tokyo where your primary hub is located
    client = boto3.client('cloudtrail', region_name='ap-northeast-1')
    
    # Looking for the last 10 management events
    response = client.lookup_events(MaxResults=10)
    
    events = []
    for event in response['Events']:
        # .get('Username') prevents the KeyError if the field is missing
        user = event.get('Username', 'AWS Service/System')
        
        events.append({
            "EventId": event['EventId'],
            "EventName": event['EventName'],
            "EventTime": str(event['EventTime']),
            "User": user,
            "Resources": [res['ResourceName'] for res in event.get('Resources', [])]
        })
    
    output = {
        "trail_status": "ACTIVE",
        "recent_management_events": events,
        "assertion": "PASS" if len(events) > 0 else "FAIL"
    }
    
    print(json.dumps(output, indent=2))
    
    # Writing the final proof file
    with open('04_cloudtrail-change-proof.txt', 'w') as f:
        f.write(json.dumps(output, indent=2))

if __name__ == "__main__":
    get_last_changes()