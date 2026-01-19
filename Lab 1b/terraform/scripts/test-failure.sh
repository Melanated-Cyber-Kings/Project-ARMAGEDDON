#!/bin/bash
echo "=== Testing Database Failure Scenario ==="

# Get RDS instance ID
RDS_ID=$(aws rds describe-db-instances \
  --query 'DBInstances[?contains(DBInstanceIdentifier, `lab1b`)].DBInstanceIdentifier' \
  --output text)

if [[ -z "$RDS_ID" ]]; then
  echo "ERROR: No RDS instance found"
  exit 1
fi

echo "1. Current RDS status:"
aws rds describe-db-instances \
  --db-instance-identifier $RDS_ID \
  --query 'DBInstances[0].DBInstanceStatus' \
  --output text

echo -e "\n2. Stopping RDS instance (simulating failure)..."
aws rds stop-db-instance --db-instance-identifier $RDS_ID

echo -e "\n3. Waiting for instance to stop (checking every 30 seconds)..."
while true; do
  STATUS=$(aws rds describe-db-instances \
    --db-instance-identifier $RDS_ID \
    --query 'DBInstances[0].DBInstanceStatus' \
    --output text)
  
  echo "   Status: $STATUS"
  
  if [[ "$STATUS" == "stopped" ]]; then
    echo "   RDS instance stopped successfully"
    break
  fi
  
  sleep 30
done

echo -e "\n4. Checking CloudWatch Alarm status..."
aws cloudwatch describe-alarms \
  --alarm-name-prefix lab1b \
  --query 'MetricAlarms[*].{Name:AlarmName, State:StateValue}' \
  --output table

echo -e "\n5. Checking Lambda execution logs..."
LAMBDA_NAME=$(aws lambda list-functions \
  --query 'Functions[?contains(FunctionName, `lab1b`)].FunctionName' \
  --output text)

if [[ -n "$LAMBDA_NAME" ]]; then
  echo "   Lambda function: $LAMBDA_NAME"
  
  # Get latest log stream
  LOG_GROUP="/aws/lambda/$LAMBDA_NAME"
  LOG_STREAM=$(aws logs describe-log-streams \
    --log-group-name $LOG_GROUP \
    --order-by LastEventTime \
    --descending \
    --max-items 1 \
    --query 'logStreams[0].logStreamName' \
    --output text)
  
  if [[ -n "$LOG_STREAM" ]]; then
    echo "   Latest log stream: $LOG_STREAM"
    aws logs get-log-events \
      --log-group-name $LOG_GROUP \
      --log-stream-name "$LOG_STREAM" \
      --limit 10 \
      --query 'events[*].message' \
      --output text
  fi
fi

echo -e "\n=== TEST COMPLETE ==="
echo "To restart RDS: aws rds start-db-instance --db-instance-identifier $RDS_ID"
